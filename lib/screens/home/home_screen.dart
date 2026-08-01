import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import '../fno/fno_screen.dart';

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
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
      Map<String, dynamic> mover, bool isGainer) {
    final color = isGainer ?
      AppTheme.green : AppTheme.red;

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: color.withOpacity(0.1),
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
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

  Widget _buildIpoCard(Map<String, dynamic> ipo) {
    final status = ipo['status'] ?? 'Unknown';
    final isOpen = status == 'Open';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ipo['companyName'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpen
                      ? AppTheme.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                    borderRadius:
                      BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isOpen
                        ? AppTheme.green
                        : Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
                Icon(Icons.calendar_today,
                  size: 12,
                  color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${ipo['openDate'] ?? ''} — '
                  '${ipo['closeDate'] ?? ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
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