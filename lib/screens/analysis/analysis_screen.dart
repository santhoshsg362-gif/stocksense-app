import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';

class AnalysisScreen extends StatefulWidget {
  final String symbol;
  final String companyName;

  const AnalysisScreen({
    super.key,
    required this.symbol,
    required this.companyName,
  });

  @override
  State<AnalysisScreen> createState() =>
    _AnalysisScreenState();
}

class _AnalysisScreenState
    extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  late WebViewController _webController;
  Map<String, dynamic>? _fundamentals;
  Map<String, dynamic>? _technicals;
  Map<String, dynamic>? _quote;
  bool _isLoadingData = true;
  String _selectedInterval = 'D';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, vsync: this);
    _initWebView();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ApiService get _api {
    final token = context.read<AuthProvider>().token;
    return ApiService(token: token);
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(
        _buildTradingViewUrl(_selectedInterval)));
  }

  String _buildTradingViewUrl(String interval) {
    return 'https://www.tradingview.com/widgetsnippet/'
      '?symbol=NSE%3A${widget.symbol}'
      '&interval=$interval'
      '&theme=dark'
      '&style=1'
      '&locale=en'
      '&toolbar_bg=%23141926'
      '&enable_publishing=false'
      '&hide_top_toolbar=false'
      '&save_image=false'
      '&container_id=tv_chart';
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final results = await Future.wait([
        _api.getStockQuote(widget.symbol)
          .catchError((_) => <String, dynamic>{}),
        _api.getFundamentals(widget.symbol)
          .catchError((_) => <String, dynamic>{}),
        _api.getTechnicals(widget.symbol)
          .catchError((_) => <String, dynamic>{}),
      ]);
      setState(() {
        _quote = results[0];
        _fundamentals = results[1];
        _technicals = results[2];
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
            CrossAxisAlignment.start,
          children: [
            Text(
              widget.symbol,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.companyName,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.psychology,
              color: AppTheme.primaryBlue,
            ),
            tooltip: 'AI Analysis',
            onPressed: () =>
              _showAiAnalysis(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: 'Chart'),
            Tab(text: 'Fundamentals'),
            Tab(text: 'Technical'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChartTab(),
          _buildFundamentalsTab(),
          _buildTechnicalsTab(),
        ],
      ),
    );
  }

  // ── Chart Tab ────────────────────────────────────
  Widget _buildChartTab() {
    return Column(
      children: [
        // Quote header
        if (_quote != null &&
            _quote!.isNotEmpty)
          _buildQuoteHeader(),

        // Interval selector
        _buildIntervalSelector(),

        // TradingView chart
        Expanded(
          child: WebViewWidget(
            controller: _webController),
        ),
      ],
    );
  }

  Widget _buildQuoteHeader() {
    final price = _quote!['price']?.toString()
      ?? '0';
    final change = double.tryParse(
      _quote!['change']?.toString() ?? '0') ?? 0;
    final changePct = double.tryParse(
      _quote!['changePercent']?.toString()
      ?? '0') ?? 0;
    final isPositive = change >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardTheme.color,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                CrossAxisAlignment.start,
              children: [
                Text(
                  'Rs. $price',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      isPositive
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                      size: 14,
                      color: isPositive
                        ? AppTheme.green
                        : AppTheme.red,
                    ),
                    Text(
                      '${change.toStringAsFixed(2)} '
                      '(${changePct.toStringAsFixed(2)}%)',
                      style: TextStyle(
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
          ),
          Column(
            crossAxisAlignment:
              CrossAxisAlignment.end,
            children: [
              _quoteDetail(
                'H',
                _quote!['high']?.toString() ?? '0',
                AppTheme.green,
              ),
              const SizedBox(height: 4),
              _quoteDetail(
                'L',
                _quote!['low']?.toString() ?? '0',
                AppTheme.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quoteDetail(
      String label, String value, Color color) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildIntervalSelector() {
    final intervals = [
      ('1m', '1'),
      ('5m', '5'),
      ('15m', '15'),
      ('1H', '60'),
      ('1D', 'D'),
      ('1W', 'W'),
      ('1M', 'M'),
    ];

    return Container(
      height: 36,
      color: Theme.of(context).cardTheme.color,
      child: Row(
        mainAxisAlignment:
          MainAxisAlignment.spaceEvenly,
        children: intervals.map((iv) {
          final isSelected =
            _selectedInterval == iv.$2;
          return GestureDetector(
            onTap: () {
              setState(() =>
                _selectedInterval = iv.$2);
              _webController.loadRequest(
                Uri.parse(
                  _buildTradingViewUrl(iv.$2)));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                  ? AppTheme.primaryBlue
                  : Colors.transparent,
                borderRadius:
                  BorderRadius.circular(6),
              ),
              child: Text(
                iv.$1,
                style: TextStyle(
                  color: isSelected
                    ? Colors.white
                    : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Fundamentals Tab ─────────────────────────────
  Widget _buildFundamentalsTab() {
    if (_isLoadingData) {
      return const Center(
        child: CircularProgressIndicator());
    }

    if (_fundamentals == null ||
        _fundamentals!.isEmpty) {
      return _buildNoData(
        'Fundamental data unavailable');
    }

    final f = _fundamentals!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
          CrossAxisAlignment.start,
        children: [

          // Company info card
          if (f['companyName'] != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                    CrossAxisAlignment.start,
                  children: [
                    Text(
                      f['companyName'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${f['sector'] ?? ''} · '
                      '${f['industry'] ?? ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    if (f['description'] != null &&
                        f['description'] != '') ...[
                      const SizedBox(height: 12),
                      Text(
                        f['description'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                        ),
                        maxLines: 4,
                        overflow:
                          TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          _sectionTitle('Valuation Metrics'),
          const SizedBox(height: 8),

          _metricsGrid([
            _MetricItem(
              'P/E Ratio',
              f['peRatio']?.toString() ?? 'N/A',
              'Price to Earnings',
              Icons.analytics_outlined,
            ),
            _MetricItem(
              'EPS',
              f['eps']?.toString() ?? 'N/A',
              'Earnings Per Share',
              Icons.monetization_on_outlined,
            ),
            _MetricItem(
              'Book Value',
              f['bookValue']?.toString() ?? 'N/A',
              'Per Share',
              Icons.menu_book_outlined,
            ),
            _MetricItem(
              'Market Cap',
              _formatMarketCap(
                f['marketCap']?.toString()),
              'Total Value',
              Icons.business_outlined,
            ),
          ]),

          const SizedBox(height: 16),
          _sectionTitle('Profitability'),
          const SizedBox(height: 8),

          _metricsGrid([
            _MetricItem(
              'ROE',
              '${f['roe']?.toString() ?? 'N/A'}%',
              'Return on Equity',
              Icons.trending_up,
            ),
            _MetricItem(
              'Debt/Equity',
              f['debtToEquity']?.toString()
                ?? 'N/A',
              'Leverage Ratio',
              Icons.account_balance_outlined,
            ),
            _MetricItem(
              'Div. Yield',
              '${f['dividendYield']?.toString() ?? 'N/A'}%',
              'Annual Dividend',
              Icons.payments_outlined,
            ),
            _MetricItem(
              '52W High',
              f['fiftyTwoWeekHigh']?.toString()
                ?? 'N/A',
              '52 Week High',
              Icons.arrow_upward,
            ),
          ]),

          const SizedBox(height: 16),
          _sectionTitle('52 Week Range'),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                      MainAxisAlignment
                        .spaceBetween,
                    children: [
                      Text(
                        'Low: ${f['fiftyTwoWeekLow'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: AppTheme.red,
                          fontWeight:
                            FontWeight.bold,
                        ),
                      ),
                      Text(
                        'High: ${f['fiftyTwoWeekHigh'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: AppTheme.green,
                          fontWeight:
                            FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.6,
                    backgroundColor: AppTheme.red
                      .withOpacity(0.2),
                    valueColor:
                      const AlwaysStoppedAnimation(
                        AppTheme.green),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsGrid(
      List<_MetricItem> items) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
        const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: items.map((item) =>
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                CrossAxisAlignment.start,
              mainAxisAlignment:
                MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        )
      ).toList(),
    );
  }

  // ── Technical Tab ────────────────────────────────
  Widget _buildTechnicalsTab() {
    if (_isLoadingData) {
      return const Center(
        child: CircularProgressIndicator());
    }

    if (_technicals == null ||
        _technicals!.isEmpty) {
      return _buildNoData(
        'Technical data unavailable');
    }

    final t = _technicals!;
    final rsi = double.tryParse(
      t['rsi']?.toString() ?? '0') ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
          CrossAxisAlignment.start,
        children: [

          // RSI Card
          _sectionTitle('RSI (14)'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                      MainAxisAlignment
                        .spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment:
                          CrossAxisAlignment.start,
                        children: [
                          Text(
                            rsi.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight:
                                FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding:
                              const EdgeInsets
                                .symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                            decoration:
                              BoxDecoration(
                              color: _rsiColor(rsi)
                                .withOpacity(0.1),
                              borderRadius:
                                BorderRadius
                                  .circular(20),
                            ),
                            child: Text(
                              t['rsiSignal']
                                ?? 'Neutral',
                              style: TextStyle(
                                color: _rsiColor(
                                  rsi),
                                fontWeight:
                                  FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: rsi / 100,
                          strokeWidth: 8,
                          backgroundColor:
                            Colors.grey
                              .withOpacity(0.2),
                          valueColor:
                            AlwaysStoppedAnimation(
                              _rsiColor(rsi)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _rsiZone(
                          '0-30',
                          'Oversold',
                          AppTheme.green,
                          rsi <= 30,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _rsiZone(
                          '30-70',
                          'Neutral',
                          Colors.orange,
                          rsi > 30 && rsi < 70,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _rsiZone(
                          '70-100',
                          'Overbought',
                          AppTheme.red,
                          rsi >= 70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          _sectionTitle('Moving Averages'),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _maRow(
                    'SMA 50',
                    t['sma50']?.toString() ?? '0',
                    t['sma200']?.toString() ?? '0',
                  ),
                  const Divider(),
                  _maRow(
                    'SMA 200',
                    t['sma200']?.toString() ?? '0',
                    t['sma50']?.toString() ?? '0',
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment:
                      MainAxisAlignment
                        .spaceBetween,
                    children: [
                      const Text(
                        'Trend Signal',
                        style: TextStyle(
                          fontWeight:
                            FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding:
                          const EdgeInsets
                            .symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        decoration: BoxDecoration(
                          color: t['smaTrend'] ==
                            'Bullish'
                            ? AppTheme.green
                              .withOpacity(0.1)
                            : AppTheme.red
                              .withOpacity(0.1),
                          borderRadius:
                            BorderRadius.circular(
                              20),
                        ),
                        child: Text(
                          t['smaTrend'] ?? 'N/A',
                          style: TextStyle(
                            color: t['smaTrend'] ==
                              'Bullish'
                              ? AppTheme.green
                              : AppTheme.red,
                            fontWeight:
                              FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          _sectionTitle('Signal Summary'),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _signalRow(
                    'RSI Signal',
                    t['rsiSignal'] ?? 'Neutral',
                    _signalColor(
                      t['rsiSignal'] ?? ''),
                  ),
                  const Divider(),
                  _signalRow(
                    'SMA Trend',
                    t['smaTrend'] ?? 'N/A',
                    t['smaTrend'] == 'Bullish'
                      ? AppTheme.green
                      : AppTheme.red,
                  ),
                  const Divider(),
                  _signalRow(
                    'Overall',
                    _overallSignal(t),
                    _signalColor(_overallSignal(t)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange
                  .withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Technical indicators are for '
                    'educational purposes only. '
                    'Not financial advice.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _maRow(String label,
      String value, String compare) {
    final v = double.tryParse(value) ?? 0;
    final c = double.tryParse(compare) ?? 0;
    final isAbove = v > c;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8),
      child: Row(
        mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isAbove
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
                size: 14,
                color: isAbove
                  ? AppTheme.green
                  : AppTheme.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rsiZone(String range, String label,
      Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 8),
      decoration: BoxDecoration(
        color: isActive
          ? color.withOpacity(0.15)
          : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
          ? Border.all(
              color: color.withOpacity(0.5))
          : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: isActive
                ? FontWeight.bold
                : FontWeight.normal,
              fontSize: 11,
            ),
          ),
          Text(
            range,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _signalRow(
      String label, String signal, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8),
      child: Row(
        mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius:
                BorderRadius.circular(20),
            ),
            child: Text(
              signal,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AI Analysis ──────────────────────────────────
  void _showAiAnalysis(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20)),
      ),
      builder: (ctx) => _AiAnalysisSheet(
        symbol: widget.symbol,
        api: _api,
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────
  Color _rsiColor(double rsi) {
    if (rsi >= 70) return AppTheme.red;
    if (rsi <= 30) return AppTheme.green;
    return Colors.orange;
  }

  Color _signalColor(String signal) {
    if (signal.toLowerCase().contains('bull') ||
        signal.toLowerCase().contains('oversold')) {
      return AppTheme.green;
    }
    if (signal.toLowerCase().contains('bear') ||
        signal.toLowerCase()
          .contains('overbought')) {
      return AppTheme.red;
    }
    return Colors.orange;
  }

  String _overallSignal(
      Map<String, dynamic> t) {
    final rsiSignal =
      t['rsiSignal']?.toString() ?? '';
    final smaTrend =
      t['smaTrend']?.toString() ?? '';

    if (smaTrend == 'Bullish' &&
        rsiSignal == 'Oversold') {
      return 'Strong Buy Signal';
    }
    if (smaTrend == 'Bullish') return 'Bullish';
    if (smaTrend == 'Bearish' &&
        rsiSignal == 'Overbought') {
      return 'Strong Sell Signal';
    }
    if (smaTrend == 'Bearish') return 'Bearish';
    return 'Neutral';
  }

  String _formatMarketCap(String? cap) {
    if (cap == null) return 'N/A';
    final num = double.tryParse(cap) ?? 0;
    if (num >= 1000000000000) {
      return '${(num / 1000000000000)
        .toStringAsFixed(1)}T';
    } else if (num >= 1000000000) {
      return '${(num / 1000000000)
        .toStringAsFixed(1)}B';
    } else if (num >= 1000000) {
      return '${(num / 1000000)
        .toStringAsFixed(1)}M';
    }
    return cap;
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNoData(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// ── AI Analysis Bottom Sheet ─────────────────────────
class _AiAnalysisSheet extends StatefulWidget {
  final String symbol;
  final ApiService api;

  const _AiAnalysisSheet({
    required this.symbol,
    required this.api,
  });

  @override
  State<_AiAnalysisSheet> createState() =>
    _AiAnalysisSheetState();
}

class _AiAnalysisSheetState
    extends State<_AiAnalysisSheet> {

  String? _analysis;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    try {
      final response = await widget.api
        .analyseStock(
          widget.symbol,
          'Give me a complete analysis of '
          '${widget.symbol} stock covering '
          'fundamentals, technicals, strengths '
          'and risks.',
        );
      setState(() {
        _analysis = response['analysis'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _analysis = 'AI analysis unavailable. '
          'Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:
        MediaQuery.of(context).size.height * 0.8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
            CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Analysis — ${widget.symbol}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Powered by Groq LLaMA 3.3',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment:
                        MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Analysing stock data...',
                          style: TextStyle(
                            color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Text(
                      _analysis ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange
                  .withOpacity(0.1),
                borderRadius:
                  BorderRadius.circular(8),
              ),
              child: const Text(
                'For educational purposes only. '
                'Not financial advice.',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Metric Item model ────────────────────────────────
class _MetricItem {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  _MetricItem(
    this.label,
    this.value,
    this.subtitle,
    this.icon,
  );
}