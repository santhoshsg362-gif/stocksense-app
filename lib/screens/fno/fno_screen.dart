import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';

class FnoScreen extends StatefulWidget {
  const FnoScreen({super.key});

  @override
  State<FnoScreen> createState() => _FnoScreenState();
}

class _FnoScreenState extends State<FnoScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _fnoData = [];
  bool _isLoading = true;
  String _selectedSymbol = 'NIFTY';
  String? _error;

  final List<String> _symbols = [
    'NIFTY', 'BANKNIFTY', 'FINNIFTY',
    'RELIANCE', 'TCS', 'INFY',
    'HDFCBANK', 'ICICIBANK', 'SBIN',
  ];

  @override
  void initState() {
    super.initState();
    _loadFno();
  }

  Future<void> _loadFno() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _api.getFno(
        _selectedSymbol);
      setState(() {
        _fnoData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load F&O data';
        _isLoading = false;
      });
    }
  }

  // Separate CE and PE data
  List<dynamic> get _ceData => _fnoData
    .where((d) => d['optionType'] == 'CE')
    .toList();

  List<dynamic> get _peData => _fnoData
    .where((d) => d['optionType'] == 'PE')
    .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Futures & Options'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFno,
          ),
        ],
      ),
      body: Column(
        children: [
          // Symbol selector
          _buildSymbolSelector(),

          // Content
          Expanded(
            child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator())
              : _error != null
                ? _buildError()
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  // ── Symbol Selector ──────────────────────────────
  Widget _buildSymbolSelector() {
    return Container(
      height: 48,
      color: Theme.of(context).cardTheme.color,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
        itemCount: _symbols.length,
        separatorBuilder: (_, __) =>
          const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final symbol = _symbols[i];
          final isSelected =
            symbol == _selectedSymbol;
          return GestureDetector(
            onTap: () {
              setState(() =>
                _selectedSymbol = symbol);
              _loadFno();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                  ? AppTheme.primaryBlue
                  : Colors.transparent,
                borderRadius:
                  BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                    ? AppTheme.primaryBlue
                    : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Text(
                symbol,
                style: TextStyle(
                  color: isSelected
                    ? Colors.white
                    : null,
                  fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Main Content ─────────────────────────────────
  Widget _buildContent() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Info header
          _buildInfoHeader(),

          // Tab bar
          TabBar(
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryBlue,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment:
                    MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Call (CE)'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment:
                    MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Put (PE)'),
                  ],
                ),
              ),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              children: [
                _buildOptionTable(
                  _ceData, true),
                _buildOptionTable(
                  _peData, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Header ──────────────────────────────────
  Widget _buildInfoHeader() {
    final expiry = _fnoData.isNotEmpty
      ? _fnoData.first['expiry'] ?? ''
      : '';

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.accentBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedSymbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (expiry.isNotEmpty)
                  Text(
                    'Expiry: $expiry',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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
                '${_ceData.length} Strikes',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Option Chain',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Option Table ─────────────────────────────────
  Widget _buildOptionTable(
      List<dynamic> data, bool isCE) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'));
    }

    final color = isCE ?
      AppTheme.green : AppTheme.red;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
            color: color.withOpacity(0.1),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Strike',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'LTP',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Change%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'OI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: color,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Table rows
          ListView.separated(
            shrinkWrap: true,
            physics:
              const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            separatorBuilder: (_, __) =>
              const Divider(height: 1),
            itemBuilder: (_, i) =>
              _buildOptionRow(data[i], isCE),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(
      Map<String, dynamic> option, bool isCE) {

    final change = double.tryParse(
      option['percentChange']?.toString() ?? '0'
    ) ?? 0;
    final isPositive = change >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Strike price
          Expanded(
            flex: 2,
            child: Text(
              option['strikePrice'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),

          // LTP
          Expanded(
            flex: 2,
            child: Text(
              option['lastPrice'] ?? '0',
              style: const TextStyle(
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Change %
          Expanded(
            flex: 2,
            child: Text(
              '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
              style: TextStyle(
                color: isPositive
                  ? AppTheme.green
                  : AppTheme.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Open Interest
          Expanded(
            flex: 3,
            child: Text(
              _formatOI(
                option['openInterest']?.toString()
                ?? '0'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatOI(String oi) {
    final num = double.tryParse(oi) ?? 0;
    if (num >= 10000000) {
      return '${(num / 10000000).toStringAsFixed(1)}Cr';
    } else if (num >= 100000) {
      return '${(num / 100000).toStringAsFixed(1)}L';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return oi;
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            onPressed: _loadFno,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}