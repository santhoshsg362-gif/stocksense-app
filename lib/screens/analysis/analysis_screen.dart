import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../providers/metrics_provider.dart';
import '../../models/stock_metrics.dart';
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
  String _selectedInterval = 'D';
  String? _aiAnalysis;
  bool _isAiLoading = false;
  int _aiScore = 0;
  Map<String, dynamic>? _financialsData;
  late WebViewController _screenerController;
  late WebViewController _ipoController;
  bool _isFinancialsLoading = false;
  List<double> _closingPrices = [];
  List<String> _priceDates = [];
  bool _isPriceLoading = true;
  double _livePrice = 0;
  double _liveChange = 0;
  double _liveChangePct = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5, vsync: this);
    _initWebView();
    _screenerController = WebViewController()
  ..setJavaScriptMode(
    JavaScriptMode.unrestricted)
  ..loadRequest(Uri.parse(
    'https://www.screener.in'
    '/company/${widget.symbol}/'));
    WidgetsBinding.instance
      .addPostFrameCallback((_) {
      _autoLoadMetrics();
      _loadLivePrice();
      _loadPriceHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ApiService get _api {
    final token =
      context.read<AuthProvider>().token;
    return ApiService(token: token);
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(
        JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.contains(
                'tradingview.com/chart/') ||
                request.url.contains(
                'tradingview.com/mobile')) {
              return NavigationDecision
                .prevent;
            }
            return NavigationDecision
              .navigate;
          },
        ),
      )
      ..loadHtmlString(
        _buildChartHtml(_selectedInterval));
  }

  String _buildChartHtml(String interval) {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" 
  content="width=device-width, 
  initial-scale=1.0, 
  maximum-scale=1.0">
<style>
* { margin: 0; padding: 0; 
  box-sizing: border-box; }
body { 
  background: #131722; 
  overflow: hidden; 
  height: 100vh;
  width: 100vw;
}
#chart { 
  width: 100%; 
  height: 100vh; 
}
</style>
</head>
<body>
<div id="chart"></div>
<script 
  type="text/javascript" 
  src="https://s3.tradingview.com/tv.js">
</script>
<script type="text/javascript">
new TradingView.widget({
  "autosize": true,
  "symbol": "NSE:${widget.symbol}",
  "interval": "$interval",
  "timezone": "Asia/Kolkata",
  "theme": "dark",
  "style": "1",
  "locale": "en",
  "toolbar_bg": "#131722",
  "enable_publishing": false,
  "withdateranges": true,
  "hide_side_toolbar": false,
  "allow_symbol_change": false,
  "save_image": false,
  "container_id": "chart",
  "hide_popup_button": true,
  "show_popup_button": false,
  "no_referral_id": true,
  "studies": [],
  "show_popup_button": false,
  "popup_width": "0",
  "popup_height": "0"
});
</script>
</body>
</html>
''';
  }

  Future<void> _loadLivePrice() async {
    try {
      final quote = await _api
        .getStockQuote(widget.symbol);
      setState(() {
        _livePrice = double.tryParse(
          quote['price']?.toString() ?? '0'
        ) ?? 0;
        _liveChange = double.tryParse(
          quote['change']?.toString() ?? '0'
        ) ?? 0;
        _liveChangePct = double.tryParse(
          quote['changePercent']
            ?.toString() ?? '0') ?? 0;
      });
    } catch (e) {
      // silent fail
    }
  }

  Future<void> _loadPriceHistory() async {
  try {
    final token =
      context.read<AuthProvider>().token;
    final api = ApiService(token: token);
    final quote = await api
      .getStockQuote(widget.symbol);

    // Build a simple price line from
    // available data
    final price = double.tryParse(
      quote['price']?.toString() ?? '0'
    ) ?? 0;
    final high = double.tryParse(
      quote['high']?.toString() ?? '0'
    ) ?? 0;
    final low = double.tryParse(
      quote['low']?.toString() ?? '0'
    ) ?? 0;
    final prevClose = double.tryParse(
      quote['previousClose']
        ?.toString() ?? '0'
    ) ?? 0;
    final open = double.tryParse(
      quote['open']?.toString() ?? '0'
    ) ?? 0;

    if (price > 0) {
      setState(() {
        // Show today's price movement
        _closingPrices = [
          prevClose,
          open,
          low,
          high,
          price,
        ].where((p) => p > 0).toList();
        _priceDates = [
          'Prev',
          'Open',
          'Low',
          'High',
          'Current',
        ];
        _isPriceLoading = false;
      });
    } else {
      setState(() =>
        _isPriceLoading = false);
    }
  } catch (e) {
    setState(() =>
      _isPriceLoading = false);
  }
}

  Future<void> _autoLoadMetrics() async {
    final provider =
      context.read<MetricsProvider>();
    if (provider.getFundamentals(
        widget.symbol).isNotEmpty) return;
    try {
      final fundData =
        await _api.getStockFundamentals(
          widget.symbol);
      final techData =
        await _api.getStockTechnicals(
          widget.symbol);
      fundData.forEach((key, value) {
        if (value == null ||
            value.toString().isEmpty ||
            value.toString() == '0' ||
            value.toString()
              .contains('unavailable'))
          return;
        provider.addFundamentalMetric(
          widget.symbol,
          FundamentalMetric(
            name: key,
            value: value.toString(),
          ),
        );
      });
      techData.forEach((key, value) {
        if (value == null ||
            value.toString().isEmpty ||
            value.toString() == '0') return;
        final parts = value.toString()
          .split(' — ');
        provider.addTechnicalMetric(
          widget.symbol,
          TechnicalMetric(
            name: key,
            value: parts[0],
            signal: parts.length > 1
              ? parts[1] : null,
          ),
        );
      });
    } catch (e) {
      debugPrint('Auto-load failed: $e');
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor:
            Colors.grey,
          indicatorColor:
            AppTheme.primaryBlue,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Chart'),
            Tab(text: 'Fundamental'),
            Tab(text: 'Technical'),
            Tab(text: 'Financials'),
            Tab(text: 'AI Analysis'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChartTab(),
          _buildFundamentalTab(),
          _buildTechnicalTab(),
          _buildFinancialsTab(),
          _buildAiTab(),
        ],
      ),
    );
  }


  // ── Chart Tab ──────────────────────────
  Widget _buildChartTab() {
    return Column(
      children: [
        _buildIntervalSelector(),
        const SizedBox(height: 8),
        if (_livePrice > 0)
          Container(
            padding:
              const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8),
            color: Theme.of(context)
              .cardTheme.color,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                      CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        widget.symbol,
                        style:
                          const TextStyle(
                          fontWeight:
                            FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        widget.companyName,
                        style: TextStyle(
                          color:
                            Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment:
                    CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${_livePrice.toStringAsFixed(2)}',
                      style:
                        const TextStyle(
                        fontSize: 22,
                        fontWeight:
                          FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          _liveChange >= 0
                            ? Icons
                                .arrow_upward
                            : Icons
                                .arrow_downward,
                          size: 12,
                          color:
                            _liveChange >= 0
                            ? AppTheme.green
                            : AppTheme.red,
                        ),
                        Text(
                          '${_liveChange >= 0 ? '+' : ''}${_liveChange.toStringAsFixed(2)} (${_liveChangePct.toStringAsFixed(2)}%)',
                          style: TextStyle(
                            color:
                              _liveChange >= 0
                              ? AppTheme.green
                              : AppTheme.red,
                            fontSize: 12,
                            fontWeight:
                              FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: _isPriceLoading
            ? const Center(
                child: CircularProgressIndicator())
            : _closingPrices.isEmpty
              ? _buildNoData(
                  'Price data unavailable')
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildPriceChart(),
                ),
        ),
      ],
    );
  }

  Widget _buildIntervalSelector() {
    final intervals = [
      ('1m', '1'), ('5m', '5'),
      ('15m', '15'), ('1H', '60'),
      ('1D', 'D'), ('1W', 'W'), ('1M', 'M'),
    ];
    return Container(
      height: 36,
      color:
        Theme.of(context).cardTheme.color,
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
              _webController.loadHtmlString(
                _buildChartHtml(iv.$2));
            },
            child: Container(
              padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4),
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

  Widget _buildPriceChart() {
    if (_closingPrices.isEmpty) {
      return _buildNoData('No price data');
    }
    final minY = _closingPrices
      .reduce((a, b) => a < b ? a : b);
    final maxY = _closingPrices
      .reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final isPositive =
      _closingPrices.last >=
      _closingPrices.first;
    return LineChart(
      LineChartData(
        minY: minY - range * 0.05,
        maxY: maxY + range * 0.05,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: range / 4,
          getDrawingHorizontalLine:
            (value) => FlLine(
              color: Colors.grey
                .withOpacity(0.2),
              strokeWidth: 1,
            ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget:
                (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[600],
                  ),
                ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval:
                (_closingPrices.length / 4)
                  .toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _priceDates.length) {
                  final date = _priceDates[index];
                  return Text(
                    date.length >= 7
                      ? date.substring(5, 7)
                      : date,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false)),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false)),
        ),
        borderData:
          FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _closingPrices
              .asMap()
              .entries
              .map((e) => FlSpot(
                e.key.toDouble(),
                e.value))
              .toList(),
            isCurved: true,
            color: isPositive
              ? AppTheme.green
              : AppTheme.red,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(
              show: false),
            belowBarData: BarAreaData(
              show: true,
              color: isPositive
                ? AppTheme.green
                    .withOpacity(0.1)
                : AppTheme.red
                    .withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData:
            LineTouchTooltipData(
            getTooltipItems: (spots) =>
              spots.map((spot) =>
                LineTooltipItem(
                  'Rs. ${spot.y.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                )
              ).toList(),
          ),
        ),
      ),
    );
  }

  // ── Fundamental Tab ────────────────────
  Widget _buildFundamentalTab() {
    final metrics = context
      .watch<MetricsProvider>()
      .getFundamentals(widget.symbol);
    return Stack(
      children: [
        metrics.isEmpty
          ? _buildEmptyMetrics(
              'No fundamental metrics yet',
              'Tap + to add metrics like '
              'P/E, ROCE, ROE, EPS...',
              Icons.analytics_outlined,
            )
          : ListView(
              padding:
                const EdgeInsets.fromLTRB(
                  16, 16, 16, 80),
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bar_chart,
                      color:
                        AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${metrics.length} '
                      'Fundamental Metrics',
                      style: const TextStyle(
                        fontWeight:
                          FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics:
                    const NeverScrollableScrollPhysics(),
                  gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: metrics.length,
                  itemBuilder: (_, i) =>
                    _buildFundamentalCard(
                      metrics[i], i),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                    const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue
                      .withOpacity(0.1),
                    borderRadius:
                      BorderRadius.circular(
                        10),
                    border: Border.all(
                      color:
                        AppTheme.primaryBlue
                          .withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.psychology,
                        color:
                          AppTheme.primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Go to AI Analysis '
                          'tab to get insights',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme
                              .primaryBlue,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                          _tabController
                            .animateTo(4),
                        child: const Text(
                          'Go →'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'fundamental_fab',
            onPressed: () =>
              _showAddFundamentalSheet(
                context),
            backgroundColor:
              AppTheme.primaryBlue,
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFundamentalCard(
      FundamentalMetric metric, int index) {
    return GestureDetector(
      onLongPress: () =>
        _showEditFundamentalSheet(
          context, metric, index),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment:
              CrossAxisAlignment.start,
            mainAxisAlignment:
              MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment:
                  MainAxisAlignment
                    .spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      metric.name,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                          Colors.grey[600],
                        fontWeight:
                          FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow:
                        TextOverflow
                          .ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context
                      .read<MetricsProvider>()
                      .removeFundamentalMetric(
                        widget.symbol,
                        index),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color:
                        Colors.grey[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                metric.value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              if (metric.description !=
                      null &&
                  metric.description!
                      .isNotEmpty)
                Text(
                  metric.description!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow:
                    TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Technical Tab ──────────────────────
  Widget _buildTechnicalTab() {
    final metrics = context
      .watch<MetricsProvider>()
      .getTechnicals(widget.symbol);
    return Stack(
      children: [
        metrics.isEmpty
          ? _buildEmptyMetrics(
              'No technical metrics yet',
              'Tap + to add indicators like '
              'RSI, MACD, Bollinger Bands...',
              Icons.show_chart,
            )
          : ListView(
              padding:
                const EdgeInsets.fromLTRB(
                  16, 16, 16, 80),
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.show_chart,
                      color:
                        AppTheme.accentBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${metrics.length} '
                      'Technical Indicators',
                      style: const TextStyle(
                        fontWeight:
                          FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...metrics.asMap().entries
                  .map((entry) =>
                    _buildTechnicalCard(
                      entry.value,
                      entry.key)),
                const SizedBox(height: 16),
                Container(
                  padding:
                    const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue
                      .withOpacity(0.1),
                    borderRadius:
                      BorderRadius.circular(
                        10),
                    border: Border.all(
                      color:
                        AppTheme.accentBlue
                          .withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.psychology,
                        color:
                          AppTheme.accentBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'AI Analysis uses '
                          'all your technical '
                          'indicators',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme
                              .accentBlue,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                          _tabController
                            .animateTo(4),
                        child: const Text(
                          'Go →'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'technical_fab',
            onPressed: () =>
              _showAddTechnicalSheet(
                context),
            backgroundColor:
              AppTheme.accentBlue,
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalCard(
      TechnicalMetric metric, int index) {
    Color signalColor = Colors.grey;
    IconData signalIcon = Icons.remove;
    if (metric.signal != null) {
      final sig =
        metric.signal!.toLowerCase();
      if (sig.contains('bull') ||
          sig.contains('buy') ||
          sig.contains('oversold') ||
          sig.contains('positive') ||
          sig.contains('above')) {
        signalColor = AppTheme.green;
        signalIcon = Icons.arrow_upward;
      } else if (sig.contains('bear') ||
          sig.contains('sell') ||
          sig.contains('overbought') ||
          sig.contains('negative') ||
          sig.contains('below')) {
        signalColor = AppTheme.red;
        signalIcon = Icons.arrow_downward;
      } else {
        signalColor = Colors.orange;
        signalIcon = Icons.remove;
      }
    }
    return Card(
      margin: const EdgeInsets.only(
        bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: signalColor
                  .withOpacity(0.1),
                borderRadius:
                  BorderRadius.circular(10),
              ),
              child: Icon(
                signalIcon,
                color: signalColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                  CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.name,
                    style: const TextStyle(
                      fontWeight:
                        FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    metric.value,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment:
                CrossAxisAlignment.end,
              children: [
                if (metric.signal != null)
                  Container(
                    padding:
                      const EdgeInsets
                        .symmetric(
                        horizontal: 8,
                        vertical: 4),
                    decoration: BoxDecoration(
                      color: signalColor
                        .withOpacity(0.1),
                      borderRadius:
                        BorderRadius.circular(
                          20),
                    ),
                    child: Text(
                      metric.signal!,
                      style: TextStyle(
                        color: signalColor,
                        fontSize: 11,
                        fontWeight:
                          FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => context
                    .read<MetricsProvider>()
                    .removeTechnicalMetric(
                      widget.symbol, index),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Financials Tab ─────────────────────
 Widget _buildFinancialsTab() {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        color: AppTheme.primaryBlue
          .withOpacity(0.1),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: AppTheme.primaryBlue,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Financial data from '
                'Screener.in',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: WebViewWidget(
          controller:
            _screenerController),
      ),
    ],
  );
}

  // ── AI Analysis Tab ────────────────────
  Widget _buildAiTab() {
    final fundamentals = context
      .read<MetricsProvider>()
      .getFundamentals(widget.symbol);
    final technicals = context
      .read<MetricsProvider>()
      .getTechnicals(widget.symbol);
    final total = fundamentals.length +
      technicals.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
          CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding:
                const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                  CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.psychology,
                        color:
                          AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI Analysis Engine',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                            FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _metricCountChip(
                        '${fundamentals.length}',
                        'Fundamental',
                        AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      _metricCountChip(
                        '${technicals.length}',
                        'Technical',
                        AppTheme.accentBlue,
                      ),
                      const SizedBox(width: 8),
                      _metricCountChip(
                        '$total',
                        'Total',
                        AppTheme.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (total == 0)
                    Container(
                      padding:
                        const EdgeInsets
                          .all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange
                          .withOpacity(0.1),
                        borderRadius:
                          BorderRadius
                            .circular(8),
                      ),
                      child: const Text(
                        'Add metrics in '
                        'Fundamental and '
                        'Technical tabs first.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment:
                        CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          'Ready to analyse '
                          '$total metrics for '
                          '${widget.symbol}',
                          style: TextStyle(
                            color:
                              Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(
                          height: 12),
                        ElevatedButton.icon(
                          onPressed:
                            _isAiLoading
                            ? null
                            : () =>
                                _runAiAnalysis(
                                  fundamentals,
                                  technicals),
                          icon: _isAiLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                  CircularProgressIndicator(
                                    strokeWidth:
                                      2,
                                    color:
                                      Colors
                                        .white,
                                  ),
                              )
                            : const Icon(
                                Icons
                                  .auto_awesome),
                          label: Text(
                            _isAiLoading
                              ? 'Analysing...'
                              : 'Analyse All '
                                '$total Metrics',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (_aiScore > 0) ...[
            const SizedBox(height: 16),
            _buildScoreCard(),
          ],
          if (_aiAnalysis != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding:
                  const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                    CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: AppTheme.gold,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'AI Analysis Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                              FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      _aiAnalysis!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding:
                        const EdgeInsets
                          .all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange
                          .withOpacity(0.1),
                        borderRadius:
                          BorderRadius
                            .circular(8),
                      ),
                      child: const Text(
                        'For educational '
                        'purposes only. '
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
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricCountChip(
      String count, String label,
      Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius:
          BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    String recommendation;
    Color scoreColor;
    IconData scoreIcon;
    if (_aiScore >= 75) {
      recommendation = 'Strong Buy';
      scoreColor = AppTheme.green;
      scoreIcon = Icons.thumb_up;
    } else if (_aiScore >= 55) {
      recommendation = 'Buy / Hold';
      scoreColor = Colors.lightGreen;
      scoreIcon = Icons.trending_up;
    } else if (_aiScore >= 40) {
      recommendation = 'Hold';
      scoreColor = Colors.orange;
      scoreIcon = Icons.pause_circle_outline;
    } else if (_aiScore >= 25) {
      recommendation = 'Sell / Hold';
      scoreColor = Colors.deepOrange;
      scoreIcon = Icons.trending_down;
    } else {
      recommendation = 'Strong Sell';
      scoreColor = AppTheme.red;
      scoreIcon = Icons.thumb_down;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _aiScore / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors
                      .grey.withOpacity(0.2),
                    valueColor:
                      AlwaysStoppedAnimation(
                        scoreColor),
                  ),
                  Text(
                    '$_aiScore',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                        FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment:
                  CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Score',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendation,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                        FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        scoreIcon,
                        size: 16,
                        color: scoreColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Based on $_aiScore/100',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                            Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAiAnalysis(
      List<FundamentalMetric> fundamentals,
      List<TechnicalMetric> technicals) async {
    setState(() {
      _isAiLoading = true;
      _aiAnalysis = null;
      _aiScore = 0;
    });
    try {
      final fundStr = fundamentals.map((m) =>
        '${m.name}: ${m.value}'
      ).join('\n');
      final techStr = technicals.map((m) =>
        '${m.name}: ${m.value}'
        '${m.signal != null ? ' — ${m.signal}' : ''}'
      ).join('\n');
      final prompt = '''
You are StockSense AI, an expert financial analyst.
Analyse the stock ${widget.symbol} (${widget.companyName}) based on these user-defined metrics:

FUNDAMENTAL ANALYSIS (${fundamentals.length} metrics):
$fundStr

TECHNICAL ANALYSIS (${technicals.length} metrics):
$techStr

Total: ${fundamentals.length + technicals.length} metrics

Provide:
1. FUNDAMENTAL SUMMARY
2. TECHNICAL SUMMARY
3. COMBINED ANALYSIS
4. RISK ASSESSMENT
5. FINAL RECOMMENDATION (Buy/Hold/Sell)
6. SCORE: XX/100 (format exactly like this)

Not financial advice. Educational only.
''';
      final response =
        await _api.askGeneral(prompt);
      final analysisText =
        response['analysis'] ?? '';
      int score = 50;
      final scoreMatch = RegExp(
        r'SCORE:\s*(\d+)/100',
        caseSensitive: false,
      ).firstMatch(analysisText);
      if (scoreMatch != null) {
        score = int.tryParse(
          scoreMatch.group(1) ?? '50'
        ) ?? 50;
      }
      setState(() {
        _aiAnalysis = analysisText;
        _aiScore = score.clamp(0, 100);
        _isAiLoading = false;
      });
    } catch (e) {
      setState(() {
        _aiAnalysis =
          'AI analysis failed. '
          'Check connection and try again.';
        _isAiLoading = false;
      });
    }
  }

  // ── Add Fundamental Sheet ──────────────
  void _showAddFundamentalSheet(
      BuildContext context) {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final suggestions = [
      'P/E Ratio', 'P/B Ratio', 'EPS',
      'ROCE', 'ROE', 'ROA',
      'Dividend Yield', 'Debt/Equity',
      'Current Ratio', 'Quick Ratio',
      'Revenue Growth', 'Profit Margin',
      'Book Value', 'Market Cap',
      '52W High', '52W Low',
      'Face Value', 'Promoter Holding %',
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
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
              const Text(
                'Add Fundamental Metric',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection:
                    Axis.horizontal,
                  itemCount:
                    suggestions.length,
                  separatorBuilder:
                    (_, __) =>
                      const SizedBox(
                        width: 8),
                  itemBuilder: (_, i) =>
                    ActionChip(
                      label: Text(
                        suggestions[i],
                        style:
                          const TextStyle(
                          fontSize: 12),
                      ),
                      onPressed: () =>
                        setSheet(() =>
                          nameCtrl.text =
                            suggestions[i]),
                    ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration:
                  const InputDecoration(
                  labelText: 'Metric Name',
                  hintText:
                    'e.g. P/E Ratio, ROCE',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueCtrl,
                decoration:
                  const InputDecoration(
                  labelText: 'Value',
                  hintText:
                    'e.g. 28.4, 18%, 2.3x',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration:
                  const InputDecoration(
                  labelText:
                    'Description (optional)',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isEmpty
                      || valueCtrl
                          .text.isEmpty)
                    return;
                  context
                    .read<MetricsProvider>()
                    .addFundamentalMetric(
                      widget.symbol,
                      FundamentalMetric(
                        name: nameCtrl.text,
                        value: valueCtrl.text,
                        description:
                          descCtrl.text
                            .isEmpty
                          ? null
                          : descCtrl.text,
                      ),
                    );
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Add Metric'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditFundamentalSheet(
      BuildContext context,
      FundamentalMetric metric,
      int index) {
    final nameCtrl = TextEditingController(
      text: metric.name);
    final valueCtrl = TextEditingController(
      text: metric.value);
    final descCtrl = TextEditingController(
      text: metric.description ?? '');
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
          children: [
            const Text(
              'Edit Metric',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration:
                const InputDecoration(
                labelText: 'Metric Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              decoration:
                const InputDecoration(
                labelText: 'Value'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration:
                const InputDecoration(
                labelText: 'Description'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context
                  .read<MetricsProvider>()
                  .updateFundamentalMetric(
                    widget.symbol, index,
                    FundamentalMetric(
                      name: nameCtrl.text,
                      value: valueCtrl.text,
                      description:
                        descCtrl.text.isEmpty
                        ? null
                        : descCtrl.text,
                    ),
                  );
                Navigator.pop(ctx);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add Technical Sheet ────────────────
  void _showAddTechnicalSheet(
      BuildContext context) {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    String signal = 'Neutral';
    final suggestions = [
      'RSI (14)', 'MACD', 'MACD Signal',
      'Bollinger Bands', 'SMA 50',
      'SMA 200', 'EMA 20', 'EMA 50',
      'Fibonacci 0.618', 'Fibonacci 0.382',
      'Volume', 'OBV', 'Stochastic',
      'ADX', 'ATR', 'CCI',
      'Pivot Point', 'Support Level',
      'Resistance Level',
    ];
    final signals = [
      'Bullish', 'Bearish', 'Neutral',
      'Overbought', 'Oversold',
      'Buy', 'Sell', 'Hold',
      'Above SMA', 'Below SMA',
      'Golden Cross', 'Death Cross',
      'Breakout', 'Breakdown',
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
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
              const Text(
                'Add Technical Indicator',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection:
                    Axis.horizontal,
                  itemCount:
                    suggestions.length,
                  separatorBuilder:
                    (_, __) =>
                      const SizedBox(
                        width: 8),
                  itemBuilder: (_, i) =>
                    ActionChip(
                      label: Text(
                        suggestions[i],
                        style:
                          const TextStyle(
                          fontSize: 12),
                      ),
                      onPressed: () =>
                        setSheet(() =>
                          nameCtrl.text =
                            suggestions[i]),
                    ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration:
                  const InputDecoration(
                  labelText:
                    'Indicator Name',
                  hintText:
                    'e.g. RSI (14), MACD',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueCtrl,
                decoration:
                  const InputDecoration(
                  labelText: 'Value',
                  hintText: 'e.g. 58.4',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: signal,
                decoration:
                  const InputDecoration(
                  labelText: 'Signal',
                ),
                items: signals.map((s) =>
                  DropdownMenuItem(
                    value: s,
                    child: Text(s),
                  )
                ).toList(),
                onChanged: (v) =>
                  setSheet(
                    () => signal = v!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isEmpty
                      || valueCtrl
                          .text.isEmpty)
                    return;
                  context
                    .read<MetricsProvider>()
                    .addTechnicalMetric(
                      widget.symbol,
                      TechnicalMetric(
                        name: nameCtrl.text,
                        value: valueCtrl.text,
                        signal: signal,
                      ),
                    );
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Add Indicator'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────
  Widget _buildEmptyMetrics(
      String title, String subtitle,
      IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
            MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoData(String message) {
    return Center(
      child: Column(
        mainAxisAlignment:
          MainAxisAlignment.center,
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