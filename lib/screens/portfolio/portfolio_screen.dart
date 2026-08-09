import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import '../analysis/analysis_screen.dart';
import '../auth/login_screen.dart';
import 'dart:async';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() =>
    _PortfolioScreenState();
}

class _PortfolioScreenState
    extends State<PortfolioScreen> {

  Timer? _refreshTimer;

  List<dynamic> _holdings = [];
  bool _isLoading = true;
  String? _error;
  Map<String, double> _livePrices = {};
  Map<String, double> _liveChangePct = {};

  @override
void initState() {
  super.initState();
  _loadHoldings();
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
    final token =
      context.read<AuthProvider>().token;
    return ApiService(token: token);
  }

  Future<void> _loadHoldings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final holdings = await _api.getHoldings();
      setState(() {
        _holdings = holdings;
        _isLoading = false;
      });
      // Load live prices after holdings load
      _loadLivePrices();
    } catch (e) {
      if (e.toString().contains(
          'TOKEN_EXPIRED')) {
        if (!mounted) return;
        await context
          .read<AuthProvider>().logout();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen()),
          (route) => false,
        );
        return;
      }
      setState(() {
        _error = 'Could not load portfolio';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLivePrices() async {
    for (var holding in _holdings) {
      try {
        final symbol =
          holding['symbol']?.toString() ?? '';
        if (symbol.isEmpty) continue;
        final quote =
          await _api.getStockQuote(symbol);
        final price = double.tryParse(
          quote['price']?.toString() ?? '0'
        ) ?? 0;
        final changePct = double.tryParse(
          quote['changePercent']
            ?.toString() ?? '0'
        ) ?? 0;
        if (price > 0 && mounted) {
          setState(() {
            _livePrices[symbol] = price;
            _liveChangePct[symbol] = changePct;
          });
        }
      } catch (e) {
        // silent fail — show buy price instead
      }
    }
  }

  double get _totalInvestment {
    return _holdings.fold(0, (sum, h) {
      return sum + (double.tryParse(
        h['totalInvestment']?.toString()
        ?? '0') ?? 0);
    });
  }

  double get _totalCurrentValue {
    return _holdings.fold(0.0, (sum, h) {
      final symbol =
        h['symbol']?.toString() ?? '';
      final livePrice =
        _livePrices[symbol] ?? 0;
      final qty = double.tryParse(
        h['quantity']?.toString() ?? '0'
      ) ?? 0;
      if (livePrice > 0) {
        return sum + (livePrice * qty);
      }
      return sum + (double.tryParse(
        h['totalInvestment']?.toString()
        ?? '0') ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHoldings,
          ),
        ],
      ),
      floatingActionButton:
        FloatingActionButton(
          onPressed: () =>
            _showAddHoldingSheet(context),
          backgroundColor: AppTheme.primaryBlue,
          child: const Icon(
            Icons.add, color: Colors.white),
        ),
      body: _isLoading
        ? const Center(
            child: CircularProgressIndicator())
        : _error != null
          ? _buildError()
          : _holdings.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
                onRefresh: _loadHoldings,
                child: SingleChildScrollView(
                  physics:
                    const AlwaysScrollableScrollPhysics(),
                  padding:
                    const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      ..._holdings.map((h) =>
                        _buildHoldingCard(h)),
                    ],
                  ),
                ),
              ),
    );
  }

  // ── Summary Card ─────────────────────────────
  Widget _buildSummaryCard() {
    final totalInvested = _totalInvestment;
    final totalCurrent = _totalCurrentValue;
    final totalPnl = totalCurrent - totalInvested;
    final totalPnlPct = totalInvested > 0
      ? (totalPnl / totalInvested * 100)
      : 0.0;
    final isProfit = totalPnl >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment:
          CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Investment',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rs. ${totalInvested.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Current value and P&L
          if (_livePrices.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                      CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Value',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Rs. ${totalCurrent.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight:
                            FontWeight.bold,
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
                      'Current Value',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Rs. ${totalCurrent.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding:
                        const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isProfit
                          ? Colors.green[700]
                          : Colors.red[700],
                        borderRadius:
                          BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${isProfit ? '+' : ''}Rs. ${totalPnl.toStringAsFixed(0)} '
                        '(${totalPnlPct.toStringAsFixed(2)}%)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          Row(
            children: [
              _summaryChip(
                Icons.pie_chart,
                '${_holdings.length} Stocks',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(
      IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
            color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Holding Card ──────────────────────────────
  Widget _buildHoldingCard(
      Map<String, dynamic> holding) {

    final symbol =
      holding['symbol']?.toString() ?? '';
    final buyPrice = double.tryParse(
      holding['buyPrice']?.toString() ?? '0'
    ) ?? 0;
    final quantity = double.tryParse(
      holding['quantity']?.toString() ?? '0'
    ) ?? 0;
    final totalInvestment = buyPrice * quantity;
    final livePrice = _livePrices[symbol] ?? 0;
    final changePct =
      _liveChangePct[symbol] ?? 0;

    // P&L calculation
    final pnl = livePrice > 0
      ? (livePrice - buyPrice) * quantity
      : 0.0;
    final pnlPct = buyPrice > 0 && livePrice > 0
      ? ((livePrice - buyPrice) /
          buyPrice * 100)
      : 0.0;
    final isProfit = pnl >= 0;
    final isDayUp = changePct >= 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisScreen(
            symbol: symbol,
            companyName:
              holding['companyName'] ?? '',
          ),
        ),
      ),
      child: Card(
        margin:
          const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // ── Header row ───────────────
              Row(
                mainAxisAlignment:
                  MainAxisAlignment
                    .spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme
                            .primaryBlue
                            .withOpacity(0.1),
                          borderRadius:
                            BorderRadius
                              .circular(10),
                        ),
                        child: Center(
                          child: Text(
                            symbol.isNotEmpty
                              ? symbol
                                  .substring(0,1)
                              : 'X',
                            style:
                              const TextStyle(
                              color: AppTheme
                                .primaryBlue,
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
                          CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            symbol,
                            style:
                              const TextStyle(
                              fontWeight:
                                FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            holding[
                              'companyName']
                              ?? '',
                            style: TextStyle(
                              color:
                                Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow:
                              TextOverflow
                                .ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Live price column
                  Column(
                    crossAxisAlignment:
                      CrossAxisAlignment.end,
                    children: [
                      Text(
                        livePrice > 0
                          ? 'Rs. ${livePrice.toStringAsFixed(2)}'
                          : 'Rs. ${buyPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight:
                            FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (livePrice > 0)
                        Row(
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
                              '${changePct.abs().toStringAsFixed(2)}% today',
                              style: TextStyle(
                                color: isDayUp
                                  ? AppTheme.green
                                  : AppTheme.red,
                                fontSize: 11,
                                fontWeight:
                                  FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Buy Price',
                          style: TextStyle(
                            color:
                              Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Details row ──────────────
              Row(
                mainAxisAlignment:
                  MainAxisAlignment
                    .spaceBetween,
                children: [
                  _holdingDetail(
                    'Qty',
                    '${quantity.toStringAsFixed(0)}',
                  ),
                  _holdingDetail(
                    'Buy Price',
                    'Rs. ${buyPrice.toStringAsFixed(2)}',
                  ),
                  _holdingDetail(
                    'Invested',
                    'Rs. ${totalInvestment.toStringAsFixed(0)}',
                  ),
                ],
              ),

              // ── P&L row ──────────────────
              if (livePrice > 0) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                    const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8),
                  decoration: BoxDecoration(
                    color: isProfit
                      ? AppTheme.green
                          .withOpacity(0.1)
                      : AppTheme.red
                          .withOpacity(0.1),
                    borderRadius:
                      BorderRadius.circular(8),
                    border: Border.all(
                      color: isProfit
                        ? AppTheme.green
                            .withOpacity(0.3)
                        : AppTheme.red
                            .withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment:
                      MainAxisAlignment
                        .spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isProfit
                              ? Icons.trending_up
                              : Icons
                                  .trending_down,
                            size: 16,
                            color: isProfit
                              ? AppTheme.green
                              : AppTheme.red,
                          ),
                          const SizedBox(
                            width: 6),
                          Text(
                            'Overall P&L',
                            style: TextStyle(
                              fontSize: 12,
                              color: isProfit
                                ? AppTheme.green
                                : AppTheme.red,
                              fontWeight:
                                FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${isProfit ? '+' : ''}Rs. ${pnl.toStringAsFixed(2)} (${pnlPct.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: isProfit
                            ? AppTheme.green
                            : AppTheme.red,
                          fontWeight:
                            FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // ── Tap hint ─────────────────
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
                    'Tap to analyse',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Action buttons ───────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                        _showEditSheet(
                          context, holding),
                      icon: const Icon(
                        Icons.edit, size: 16),
                      label:
                        const Text('Edit'),
                      style:
                        OutlinedButton.styleFrom(
                        padding:
                          const EdgeInsets
                            .symmetric(
                            vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                        _deleteHolding(
                          holding['id']),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: AppTheme.red,
                      ),
                      label: const Text(
                        'Delete',
                        style: TextStyle(
                          color: AppTheme.red),
                      ),
                      style:
                        OutlinedButton.styleFrom(
                        padding:
                          const EdgeInsets
                            .symmetric(
                            vertical: 8),
                        side: const BorderSide(
                          color: AppTheme.red),
                      ),
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

  Widget _holdingDetail(
      String label, String value) {
    return Column(
      crossAxisAlignment:
        CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Add Holding Sheet ────────────────────────
  void _showAddHoldingSheet(
      BuildContext context) {
    final searchCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    List<dynamic> searchResults = [];
    bool isSearching = false;
    Map<String, dynamic>? selectedStock;
    String exchange = 'NSE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SizedBox(
          height: MediaQuery.of(ctx)
            .size.height * 0.85,
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
                const Text(
                  'Add to Portfolio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (selectedStock == null) ...[
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText:
                        'Search stock...',
                      prefixIcon: const Icon(
                        Icons.search),
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
                          await _api
                            .searchStocks(value);
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
                  const SizedBox(height: 12),
                  Expanded(
                    child: searchResults.isEmpty
                      ? Center(
                          child: Text(
                            searchCtrl.text
                                .length < 2
                              ? 'Type to search'
                              : 'No results',
                            style: TextStyle(
                              color:
                                Colors.grey[600]),
                          ),
                        )
                      : ListView.separated(
                          itemCount:
                            searchResults.length,
                          separatorBuilder:
                            (_, __) => const
                              Divider(height: 1),
                          itemBuilder: (_, i) {
                            final stock =
                              searchResults[i];
                            final change =
                              double.tryParse(
                                stock[
                                  'percentChange']
                                  ?.toString()
                                  ?? '0') ?? 0;
                            final isPos =
                              change >= 0;
                            return ListTile(
                              leading:
                                CircleAvatar(
                                backgroundColor:
                                  AppTheme
                                    .primaryBlue
                                    .withOpacity(
                                      0.1),
                                child: Text(
                                  (stock['symbol']
                                    ?? 'X')
                                    .substring(
                                      0, 1),
                                  style:
                                    const TextStyle(
                                    color: AppTheme
                                      .primaryBlue,
                                    fontWeight:
                                      FontWeight
                                        .bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                stock['symbol']
                                  ?? '',
                                style:
                                  const TextStyle(
                                  fontWeight:
                                    FontWeight
                                      .bold,
                                ),
                              ),
                              subtitle: Text(
                                stock[
                                  'companyName']
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
                                children: [
                                  Text(
                                    'Rs. ${stock['currentPrice']}',
                                    style:
                                      const TextStyle(
                                      fontWeight:
                                        FontWeight
                                          .bold,
                                    ),
                                  ),
                                  Text(
                                    '${isPos ? '+' : ''}${change.toStringAsFixed(2)}%',
                                    style:
                                      TextStyle(
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
                              onTap: () {
                                setSheetState(
                                  () {
                                  selectedStock =
                                    stock;
                                  priceCtrl.text =
                                    stock[
                                      'currentPrice']
                                      ?.toString()
                                      ?? '';
                                  exchange =
                                    stock[
                                      'exchange']
                                      ?? 'NSE';
                                });
                              },
                            );
                          },
                        ),
                  ),
                ],

                if (selectedStock != null) ...[
                  Container(
                    padding:
                      const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue
                        .withOpacity(0.1),
                      borderRadius:
                        BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                            AppTheme.primaryBlue,
                          child: Text(
                            (selectedStock![
                              'symbol'] ?? 'X')
                              .substring(0, 1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight:
                                FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                              CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                selectedStock![
                                  'symbol'] ?? '',
                                style:
                                  const TextStyle(
                                  fontWeight:
                                    FontWeight
                                      .bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                selectedStock![
                                  'companyName']
                                  ?? '',
                                style: TextStyle(
                                  color:
                                    Colors
                                      .grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                            setSheetState(() =>
                              selectedStock =
                                null),
                          child: const Text(
                            'Change'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    decoration:
                      const InputDecoration(
                      labelText: 'Buy Price',
                      prefixText: 'Rs. ',
                      helperText:
                        'Current price pre-filled',
                    ),
                    keyboardType:
                      TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyCtrl,
                    autofocus: true,
                    decoration:
                      const InputDecoration(
                      labelText:
                        'Quantity (shares)',
                    ),
                    keyboardType:
                      TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: exchange,
                    decoration:
                      const InputDecoration(
                      labelText: 'Exchange',
                    ),
                    items: ['NSE', 'BSE'].map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      )
                    ).toList(),
                    onChanged: (v) =>
                      setSheetState(
                        () => exchange = v!),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (qtyCtrl.text.isEmpty
                          || priceCtrl
                              .text.isEmpty) {
                        return;
                      }
                      try {
                        await _api.addHolding({
                          'symbol':
                            selectedStock![
                              'symbol'],
                          'companyName':
                            selectedStock![
                              'companyName'],
                          'buyPrice':
                            double.parse(
                              priceCtrl.text),
                          'quantity':
                            double.parse(
                              qtyCtrl.text),
                          'exchange': exchange,
                        });
                        if (!context.mounted)
                          return;
                        Navigator.pop(ctx);
                        _loadHoldings();
                        ScaffoldMessenger.of(
                          context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${selectedStock!['symbol']} added'),
                            backgroundColor:
                              AppTheme.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Failed to add'),
                            backgroundColor:
                              AppTheme.red,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Add to Portfolio'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Edit Sheet ────────────────────────────────
  void _showEditSheet(
      BuildContext context,
      Map<String, dynamic> holding) {
    final priceCtrl = TextEditingController(
      text: holding['buyPrice']
        ?.toString() ?? '');
    final qtyCtrl = TextEditingController(
      text: holding['quantity']
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
          children: [
            Text(
              'Edit ${holding['symbol']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(
                labelText: 'Buy Price',
                prefixText: 'Rs. ',
              ),
              keyboardType:
                TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(
                labelText: 'Quantity',
              ),
              keyboardType:
                TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _api.updateHolding(
                    holding['id'],
                    {
                      'symbol':
                        holding['symbol'],
                      'companyName':
                        holding['companyName'],
                      'buyPrice': double.parse(
                        priceCtrl.text),
                      'quantity': double.parse(
                        qtyCtrl.text),
                      'exchange':
                        holding['exchange'],
                    },
                  );
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  _loadHoldings();
                } catch (e) {
                  ScaffoldMessenger.of(context)
                    .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Failed to update')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete ────────────────────────────────────
  Future<void> _deleteHolding(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Stock'),
        content: const Text(
          'Remove from portfolio?'),
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
              'Delete',
              style: TextStyle(
                color: AppTheme.red),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _api.deleteHolding(id);
      _loadHoldings();
    }
  }

  // ── Empty and Error ───────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment:
          MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No stocks yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first stock',
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
            onPressed: _loadHoldings,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}