import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';

class TradebookScreen extends StatefulWidget {
  const TradebookScreen({super.key});

  @override
  State<TradebookScreen> createState() =>
    _TradebookScreenState();
}

class _TradebookScreenState
    extends State<TradebookScreen> {

  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  ApiService get _api {
    final token =
      context.read<AuthProvider>().token;
    return ApiService(token: token);
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data =
        await _api.getTransactions();
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tradebook'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _isLoading
        ? const Center(
            child: CircularProgressIndicator())
        : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment:
                  MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                    size: 48,
                    color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('Error: $_error'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed:
                      _loadTransactions,
                    child:
                      const Text('Retry'),
                  ),
                ],
              ),
            )
          : _transactions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment:
                    MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons
                        .receipt_long_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No transactions yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                          FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buy or sell stocks to '
                      'see history here',
                      style: TextStyle(
                        color:
                          Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding:
                  const EdgeInsets.all(16),
                itemCount:
                  _transactions.length,
                separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                  _buildCard(
                    _transactions[i]),
              ),
    );
  }

  Widget _buildCard(
      Map<String, dynamic> tx) {
    final isBuy = tx['type'] == 'BUY';
    final color = isBuy
      ? AppTheme.green : AppTheme.red;
    final price = double.tryParse(
      tx['price']?.toString() ?? '0'
    ) ?? 0;
    final qty = double.tryParse(
      tx['quantity']?.toString() ?? '0'
    ) ?? 0;
    final total = double.tryParse(
      tx['totalAmount']?.toString() ?? '0'
    ) ?? (price * qty);

    String dateStr = '';
    try {
      final raw =
        tx['dateTime']?.toString() ?? '';
      final dt = DateTime.parse(raw);
      dateStr =
        '${dt.day.toString().padLeft(2,'0')}/'
        '${dt.month.toString().padLeft(2,'0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2,'0')}:'
        '${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      dateStr =
        tx['dateTime']?.toString() ?? '';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                  color.withOpacity(0.1),
                borderRadius:
                  BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  isBuy ? 'BUY' : 'SELL',
                  style: TextStyle(
                    color: color,
                    fontWeight:
                      FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                  CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['symbol'] ?? '',
                    style: const TextStyle(
                      fontWeight:
                        FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    tx['companyName'] ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow:
                      TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.grey[500],
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
                  'Rs. ${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight:
                      FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                Text(
                  '${qty.toStringAsFixed(0)}'
                  ' @ Rs.'
                  ' ${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}