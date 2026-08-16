import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import '../fno/fno_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../analysis/analysis_screen.dart';
import '../analysis/analysis_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _indices = [];
  List<dynamic> _gainers = [];
  List<dynamic> _losers = [];
  List<dynamic> _ipos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getIndices(),
        _api.getGainers(),
        _api.getLosers(),
        _api.getIpos(),
      ]);
      setState(() {
        _indices = results[0];
        _gainers = results[1];
        _losers  = results[2];
        _ipos    = results[3];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Cannot connect to server. '
          'Make sure backend is running.';
        _isLoading = false;
      });
    }
  }
  ApiService get _apiWithToken {
  final token = context.read<AuthProvider>().token;
  return ApiService(token: token);
}

void _showSearchSheet(BuildContext context) {
  final searchCtrl = TextEditingController();
  List<dynamic> searchResults = [];
  bool isSearching = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => SizedBox(
        height:
          MediaQuery.of(ctx).size.height * 0.9,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx)
              .viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment:
              CrossAxisAlignment.start,
            children: [

              // Header
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Search Stocks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                      Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search field
              TextField(
                controller: searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText:
                    'Search by name or symbol...',
                  prefixIcon:
                    const Icon(Icons.search),
                  suffixIcon: isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child:
                            CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
                      )
                    : null,
                ),
                onChanged: (value) async {
                  if (value.length < 2) {
                    setSheetState(() =>
                      searchResults = []);
                    return;
                  }
                  setSheetState(() =>
                    isSearching = true);
                  try {
                    final results =
                      await _api.searchStocks(
                        value);
                    setSheetState(() {
                      searchResults = results;
                      isSearching = false;
                    });
                  } catch (e) {
                    setSheetState(() =>
                      isSearching = false);
                  }
                },
              ),

              const SizedBox(height: 16),

              // Results
              Expanded(
                child: searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment:
                          MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            searchCtrl.text.length
                                < 2
                              ? 'Type to search\nstocks and indices'
                              : 'No stocks found',
                            textAlign:
                              TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount:
                        searchResults.length,
                      separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final stock =
                          searchResults[i];
                        final change =
                          double.tryParse(
                            stock['percentChange']
                              ?.toString()
                              ?? '0') ?? 0;
                        final isPos = change >= 0;

                        return ListTile(
                          contentPadding:
                            const EdgeInsets
                              .symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                          leading: CircleAvatar(
                            backgroundColor:
                              AppTheme.primaryBlue
                                .withOpacity(0.1),
                            child: Text(
                              (stock['symbol']
                                ?? 'X')
                                .substring(0, 1),
                              style:
                                const TextStyle(
                                color: AppTheme
                                  .primaryBlue,
                                fontWeight:
                                  FontWeight.bold,
                              ),
                            ),
                          ),

                          // Stock name and symbol
                          title: Text(
                            stock['symbol'] ?? '',
                            style: const TextStyle(
                              fontWeight:
                                FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            stock['companyName']
                              ?? '',
                            maxLines: 1,
                            overflow:
                              TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),

                          // Price and change
                          trailing: Row(
                            mainAxisSize:
                              MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment:
                                  MainAxisAlignment
                                    .center,
                                crossAxisAlignment:
                                  CrossAxisAlignment
                                    .end,
                                children: [
                                  Text(
                                    'Rs. ${stock['currentPrice']}',
                                    style:
                                      const TextStyle(
                                      fontWeight:
                                        FontWeight
                                          .bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${isPos ? '+' : ''}${change.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      color: isPos
                                        ? AppTheme
                                            .green
                                        : AppTheme
                                            .red,
                                      fontSize: 11,
                                      fontWeight:
                                        FontWeight
                                          .w600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                width: 8),

                              // Add to watchlist button
                              GestureDetector(
                                onTap: () async {
                                  await _addToWatchlist(
                                    stock,
                                    ctx,
                                    setSheetState,
                                    searchResults,
                                    i,
                                  );
                                },
                                child: Container(
                                  padding:
                                    const EdgeInsets
                                      .all(6),
                                  decoration:
                                    BoxDecoration(
                                    color: AppTheme
                                      .primaryBlue
                                      .withOpacity(
                                        0.1),
                                    borderRadius:
                                      BorderRadius
                                        .circular(8),
                                    border:
                                      Border.all(
                                      color:
                                        AppTheme
                                          .primaryBlue
                                          .withOpacity(
                                            0.3),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons
                                      .bookmark_add_outlined,
                                    size: 18,
                                    color: AppTheme
                                      .primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Tap row to open analysis
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                  AnalysisScreen(
                                    symbol: stock[
                                      'symbol']
                                      ?? '',
                                    companyName:
                                      stock[
                                        'companyName']
                                        ?? '',
                                  ),
                              ),
                            );
                          },
                        );
                      },
                    ),
              ),

              // Bottom hint
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment:
                  MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 12,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap row to analyse  ·  ',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                  const Icon(
                    Icons.bookmark_add_outlined,
                    size: 12,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'to add to watchlist',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _addToWatchlist(
    Map<String, dynamic> stock,
    BuildContext sheetCtx,
    StateSetter setSheetState,
    List<dynamic> results,
    int index) async {
  try {
    await _apiWithToken.addToWatchlist({
      'symbol': stock['symbol'],
      'companyName': stock['companyName'],
      'exchange': stock['exchange'] ?? 'NSE',
      'addedPrice': double.parse(
        stock['currentPrice']
          ?.toString() ?? '0'),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${stock['symbol']} added to watchlist'),
        backgroundColor: AppTheme.green,
        duration: const Duration(seconds: 2),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${stock['symbol']} already in watchlist'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.candlestick_chart,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text('StockSense'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchSheet(context),
            tooltip: 'Search stocks',
          ),
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'F&O',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FnoScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
        ? const Center(
            child: CircularProgressIndicator())
        : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics:
                  const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                    CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(),
                    const SizedBox(height: 16),
                    _buildIndicesSection(),
                    const SizedBox(height: 24),
                    _buildGainersLosersSection(),
                    const SizedBox(height: 24),
                    _buildIpoSection(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Greeting ─────────────────────────────────────
  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting = hour < 12
      ? 'Good Morning'
      : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.accentBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Indian Markets',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, dd MMM yyyy')
                    .format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.trending_up,
            color: Colors.white,
            size: 48,
          ),
        ],
      ),
    );
  }

  // ── Indices ──────────────────────────────────────
  Widget _buildIndicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Market Indices'),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: _indices.isEmpty
            ? const Center(
                child: Text('No index data'))
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _indices.length,
                separatorBuilder: (_, __) =>
                  const SizedBox(width: 12),
                itemBuilder: (_, i) =>
                  _buildIndexCard(_indices[i]),
              ),
        ),
      ],
    );
  }

  Widget _buildIndexCard(Map<String, dynamic> index) {
    final change = double.tryParse(
      index['percentChange']?.toString() ?? '0'
    ) ?? 0;
    final isPositive = change >= 0;

    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPositive
            ? AppTheme.green.withOpacity(0.3)
            : AppTheme.red.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            index['name'] ?? '',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            index['lastPrice'] ?? '0',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
                size: 12,
                color: isPositive
                  ? AppTheme.green
                  : AppTheme.red,
              ),
              const SizedBox(width: 2),
              Text(
                '${change.abs().toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: isPositive
                    ? AppTheme.green
                    : AppTheme.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Gainers and Losers ───────────────────────────
  Widget _buildGainersLosersSection() {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Market Movers'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                TabBar(
                  tabs: const [
                    Tab(text: 'Top Gainers'),
                    Tab(text: 'Top Losers'),
                  ],
                  labelColor: AppTheme.primaryBlue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryBlue,
                  dividerColor: Colors.transparent,
                ),
                SizedBox(
                  height: 280,
                  child: TabBarView(
                    children: [
                      _buildMoverList(
                        _gainers, true),
                      _buildMoverList(
                        _losers, false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoverList(
      List<dynamic> movers, bool isGainer) {
    if (movers.isEmpty) {
      return const Center(
        child: Text('No data available'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: movers.length > 5 ?
        5 : movers.length,
      separatorBuilder: (_, __) =>
        const Divider(height: 1),
      itemBuilder: (_, i) =>
        _buildMoverTile(movers[i], isGainer),
    );
  }

  Widget _buildMoverTile(
    Map<String, dynamic> mover,
    bool isGainer) {
  final color = isGainer
    ? AppTheme.green : AppTheme.red;

  return GestureDetector(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalysisScreen(
          symbol:
            mover['symbol'] ?? '',
          companyName:
            mover['companyName']
              ?? mover['symbol']
              ?? '',
        ),
      ),
    ),
    child: ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor:
          color.withOpacity(0.1),
        child: Text(
          (mover['symbol'] ?? 'X')
            .substring(0, 1),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        mover['symbol'] ?? '',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      subtitle: Text(
        mover['companyName'] ?? '',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment:
          MainAxisAlignment.center,
        crossAxisAlignment:
          CrossAxisAlignment.end,
        children: [
          Text(
            mover['lastPrice'] ?? '0',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            '${isGainer ? '+' : ''}${mover['percentChange'] ?? '0'}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

  // ── IPO Section ──────────────────────────────────
  Widget _buildIpoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('IPO Watch'),
        const SizedBox(height: 12),
        _ipos.isEmpty
          ? Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No active IPOs right now',
                    style: TextStyle(
                      color: Colors.grey[600]),
                  ),
                ),
              ),
            )
          : Column(
              children: _ipos.map(
                (ipo) => _buildIpoCard(ipo)).toList(),
            ),
      ],
    );
  }

 Widget _buildIpoCard(
    Map<String, dynamic> ipo) {
  final status = ipo['status'] ?? 'Unknown';
  final isOpen = status == 'Open' ||
    status == 'Active';

  // Check if this is a placeholder
  final isPlaceholder =
    ipo['openDate'] == 'N/A' ||
    (ipo['companyName'] as String)
      .contains('chittorgarh') ||
    (ipo['companyName'] as String)
      .contains('unavailable');

  if (isPlaceholder) {
    return Card(
      margin:
        const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(
          Icons.open_in_browser,
          color: AppTheme.primaryBlue,
        ),
        title: const Text(
          'View Current IPOs'),
        subtitle: const Text(
          'Tap to see live IPO listings'),
        trailing: const Icon(
          Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
              _IpoWebView()),
        ),
      ),
    );
  }

  return GestureDetector(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _IpoWebView()),
    ),
    child: Card(
      margin:
        const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding:
          const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
            CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                MainAxisAlignment
                  .spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ipo['companyName'] ?? '',
                    style: const TextStyle(
                      fontWeight:
                        FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding:
                    const EdgeInsets
                      .symmetric(
                      horizontal: 8,
                      vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpen
                      ? AppTheme.green
                          .withOpacity(0.1)
                      : Colors.orange
                          .withOpacity(0.1),
                    borderRadius:
                      BorderRadius
                        .circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isOpen
                        ? AppTheme.green
                        : Colors.orange,
                      fontSize: 11,
                      fontWeight:
                        FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _ipoDetail(
                  'Price',
                  ipo['issuePrice'] ?? 'TBA'),
                _ipoDetail(
                  'Lot Size',
                  ipo['lotSize'] ?? 'TBA'),
                _ipoDetail(
                  'Issue Size',
                  ipo['issueSize'] ?? 'TBA'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${ipo['openDate'] ?? ''}'
                  ' — '
                  '${ipo['closeDate'] ?? ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap for details →',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                      AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _ipoDetail(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error ────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper ───────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _IpoWebView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(
        JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(
        'https://www.chittorgarh.com'
        '/report/ipo/9/'));
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Current IPOs'),
      ),
      body: WebViewWidget(
        controller: controller),
    );
  }
}