import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import '../analysis/analysis_screen.dart';
import 'dart:async';
import '../../services/alert_service.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() =>
    _WatchlistScreenState();
}

class _WatchlistScreenState
    extends State<WatchlistScreen> {

  Map<String, double> _livePrices = {};
  Map<String, double> _liveChangePct = {};
  Timer? _refreshTimer;

  List<dynamic> _watchlist = [];
  bool _isLoading = true;
  String? _error;

  @override
void initState() {
  super.initState();
  _loadWatchlist();
  // Auto refresh every 30 seconds
  _refreshTimer = Timer.periodic(
    const Duration(seconds: 30),
    (_) => _loadLivePrices(),
  );
}

@override
void dispose() {
  _refreshTimer?.cancel();
  super.dispose();
}

  ApiService get _api {
    final token = context.read<AuthProvider>().token;
    return ApiService(token: token);
  }

 Future<void> _loadWatchlist() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });
  try {
    final data = await _api.getWatchlist();
    setState(() {
      _watchlist = data;
      _isLoading = false;
    });
    _loadLivePrices(); // add this line
  } catch (e) {
    if (e.toString().contains(
        'TOKEN_EXPIRED')) {
      if (!mounted) return;
      await context
        .read<AuthProvider>().logout();
      return;
    }
    setState(() {
      _error = 'Could not load watchlist';
      _isLoading = false;
    });
  }
}

  double _getPriceDiff(
      double addedPrice, double currentPrice) {
    if (addedPrice == 0) return 0;
    return ((currentPrice - addedPrice) /
      addedPrice) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWatchlist,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
          _showSearchSheet(context),
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(
          Icons.add, color: Colors.white),
      ),
      body: _isLoading
        ? const Center(
            child: CircularProgressIndicator())
        : _error != null
          ? _buildError()
          : _watchlist.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
                onRefresh: _loadWatchlist,
                child: ListView.builder(
                  padding:
                    const EdgeInsets.all(16),
                  itemCount: _watchlist.length,
                  itemBuilder: (_, i) =>
                    _buildWatchlistCard(
                      _watchlist[i]),
                ),
              ),
    );
  }

  // ── Watchlist Card ───────────────────────────────
  Widget _buildWatchlistCard(
      Map<String, dynamic> item) {

    final addedPrice = double.tryParse(
      item['addedPrice']?.toString() ?? '0')
      ?? 0;
    final currentPrice = addedPrice;
    final priceDiff = _getPriceDiff(
      addedPrice, currentPrice);
    final isPositive = priceDiff >= 0;
    final targetPrice = item['targetPrice'] != null
      ? double.tryParse(
          item['targetPrice'].toString())
      : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisScreen(
            symbol: item['symbol'] ?? '',
            companyName:
              item['companyName'] ?? '',
          ),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // ── Header row ──────────────────
              Row(
                mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue
                            .withOpacity(0.1),
                          borderRadius:
                            BorderRadius.circular(
                              10),
                        ),
                        child: Center(
                          child: Text(
                            (item['symbol'] ?? 'X')
                              .substring(0, 1),
                            style: const TextStyle(
                              color:
                                AppTheme.accentBlue,
                              fontWeight:
                                FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment:
                          CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['symbol'] ?? '',
                            style: const TextStyle(
                              fontWeight:
                                FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            item['companyName']
                              ?? '',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow:
                              TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.red,
                      size: 20,
                    ),
                    onPressed: () =>
                      _removeFromWatchlist(
                        item['id']),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Price comparison ─────────────
Builder(builder: (context) {
  final symbol =
    item['symbol']?.toString() ?? '';
  final addedPrice = double.tryParse(
    item['addedPrice']?.toString()
    ?? '0') ?? 0;
  final livePrice =
    _livePrices[symbol] ?? 0;
  final currentPrice = livePrice > 0
    ? livePrice : addedPrice;
  final priceDiff = addedPrice > 0
    ? ((currentPrice - addedPrice) /
        addedPrice * 100)
    : 0.0;
  final isPositive = priceDiff >= 0;
  final dayChangePct =
    _liveChangePct[symbol] ?? 0;
  final isDayUp = dayChangePct >= 0;

  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _priceBox(
              'Added Price',
              'Rs. ${addedPrice.toStringAsFixed(2)}',
              Colors.grey[700]!,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _priceBox(
              'Current Price',
              livePrice > 0
                ? 'Rs. ${livePrice.toStringAsFixed(2)}'
                : 'Loading...',
              AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _priceBox(
              'Since Added',
              '${isPositive ? '+' : ''}${priceDiff.toStringAsFixed(2)}%',
              isPositive
                ? AppTheme.green
                : AppTheme.red,
            ),
          ),
        ],
      ),
      if (livePrice > 0) ...[
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment:
            MainAxisAlignment.end,
          children: [
            Icon(
              isDayUp
                ? Icons.arrow_upward
                : Icons.arrow_downward,
              size: 11,
              color: isDayUp
                ? AppTheme.green
                : AppTheme.red,
            ),
            Text(
              '${dayChangePct.abs().toStringAsFixed(2)}% today',
              style: TextStyle(
                fontSize: 11,
                color: isDayUp
                  ? AppTheme.green
                  : AppTheme.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ],
  );
}),

              // ── Target price ─────────────────
              if (targetPrice != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                    const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.gold
                      .withOpacity(0.1),
                    borderRadius:
                      BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.gold
                        .withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flag,
                        size: 14,
                        color: AppTheme.gold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Target: Rs. ${targetPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontSize: 13,
                          fontWeight:
                            FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${((targetPrice - currentPrice) / currentPrice * 100).toStringAsFixed(1)}% away',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // ── Action buttons ───────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                        _showSetTargetSheet(
                          context, item),
                      icon: const Icon(
                        Icons.flag_outlined,
                        size: 14),
                      label: Text(
                        targetPrice != null
                          ? 'Edit Target'
                          : 'Set Target',
                      ),
                      style:
                        OutlinedButton.styleFrom(
                        padding:
                          const EdgeInsets
                            .symmetric(
                            vertical: 8),
                        textStyle:
                          const TextStyle(
                            fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                              AnalysisScreen(
                                symbol:
                                  item['symbol']
                                    ?? '',
                                companyName:
                                  item[
                                    'companyName']
                                    ?? '',
                              ),
                          ),
                        ),
                      icon: const Icon(
                        Icons.analytics_outlined,
                        size: 14,
                      ),
                      label: const Text(
                        'Analyse'),
                      style:
                        OutlinedButton.styleFrom(
                        padding:
                          const EdgeInsets
                            .symmetric(
                            vertical: 8),
                        textStyle:
                          const TextStyle(
                            fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),

              // Tap hint
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment:
                  MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 11,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap card to analyse',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[400],
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

  Widget _priceBox(
      String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment:
          CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Sheet ─────────────────────────────────
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
            MediaQuery.of(ctx).size.height * 0.85,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx)
                .viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment:
                CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add to Watchlist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
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
                          padding:
                            EdgeInsets.all(12),
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
                Expanded(
                  child: searchResults.isEmpty
                    ? Center(
                        child: Text(
                          searchCtrl.text.length
                              < 2
                            ? 'Type at least 2 '
                              'characters to search'
                            : 'No stocks found',
                          style: TextStyle(
                            color: Colors.grey[600]),
                          textAlign:
                            TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount:
                          searchResults.length,
                        separatorBuilder:
                          (_, __) =>
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
                            title: Text(
                              stock['symbol'] ?? '',
                              style:
                                const TextStyle(
                                fontWeight:
                                  FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              stock['companyName']
                                ?? '',
                              maxLines: 1,
                              overflow:
                                TextOverflow
                                  .ellipsis,
                            ),
                            trailing: Column(
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
                                  ),
                                ),
                              ],
                            ),
                            onTap: () async {
                              await _addToWatchlist(
                                stock, ctx);
                            },
                          );
                        },
                      ),
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
      BuildContext sheetCtx) async {
    try {
      await _api.addToWatchlist({
        'symbol': stock['symbol'],
        'companyName': stock['companyName'],
        'exchange': stock['exchange'] ?? 'NSE',
        'addedPrice': double.parse(
          stock['currentPrice']
            ?.toString() ?? '0'),
      });
      if (!mounted) return;
      Navigator.pop(sheetCtx);
      _loadWatchlist();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${stock['symbol']} added to watchlist'),
          backgroundColor: AppTheme.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Already in watchlist'),
          backgroundColor: AppTheme.red,
        ),
      );
    }
  }

  // ── Set Target Sheet ─────────────────────────────
  void _showSetTargetSheet(
      BuildContext context,
      Map<String, dynamic> item) {
    final targetCtrl = TextEditingController(
      text: item['targetPrice']
        ?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx)
            .viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
            CrossAxisAlignment.start,
          children: [
            Text(
              'Set Target — ${item['symbol']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Added at: Rs. ${item['addedPrice']}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Target Price',
                prefixText: 'Rs. ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (targetCtrl.text.isEmpty)
                  return;
                try {
                  await _api.removeFromWatchlist(
                    item['id']);
                  await _api.addToWatchlist({
                    'symbol': item['symbol'],
                    'companyName':
                      item['companyName'],
                    'exchange': item['exchange'],
                    'addedPrice': item['addedPrice'],
                    'targetPrice': double.parse(
                      targetCtrl.text),
                  });
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  _loadWatchlist();
                } catch (e) {
                  ScaffoldMessenger.of(context)
                    .showSnackBar(
                    const SnackBar(
                      content: Text('Failed')),
                  );
                }
              },
              child: const Text('Save Target'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeFromWatchlist(
      int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Stock'),
        content: const Text(
          'Remove from watchlist?'),
        actions: [
          TextButton(
            onPressed: () =>
              Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
              Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(
                color: AppTheme.red),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _api.removeFromWatchlist(id);
      _loadWatchlist();
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment:
          MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Watchlist is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to search and add stocks',
            style: TextStyle(
              color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment:
          MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(_error ?? 'Something went wrong'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadWatchlist,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

 Future<void> _loadLivePrices() async {
  for (var item in _watchlist) {
    try {
      final symbol =
        item['symbol']?.toString() ?? '';
      if (symbol.isEmpty) continue;
      final quote =
        await _api.getStockQuote(symbol);
      final price = double.tryParse(
        quote['price']?.toString() ?? '0'
      ) ?? 0;
      final changePct = double.tryParse(
        quote['changePercent']
          ?.toString() ?? '0') ?? 0;
      if (price > 0 && mounted) {
        setState(() {
          _livePrices[symbol] = price;
          _liveChangePct[symbol] = changePct;
        });

        // Check watchlist target
        final targetPrice = double.tryParse(
          item['targetPrice']
            ?.toString() ?? '0') ?? 0;
        if (targetPrice > 0 &&
            price >= targetPrice) {
          await AlertService.showAlert(
            title:
              '🎯 Target Hit — $symbol',
            body:
              '$symbol on your watchlist '
              'has reached Rs. '
              '${price.toStringAsFixed(2)}, '
              'your target of Rs. '
              '${targetPrice.toStringAsFixed(2)}',
          );
        }
      }
    } catch (e) {
      // silent fail
    }
  }
}

}