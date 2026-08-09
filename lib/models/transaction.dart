class Transaction {
  final int id;
  final String symbol;
  final String companyName;
  final String type; // BUY or SELL
  final double price;
  final double quantity;
  final double totalAmount;
  final String dateTime;

  Transaction({
    required this.id,
    required this.symbol,
    required this.companyName,
    required this.type,
    required this.price,
    required this.quantity,
    required this.totalAmount,
    required this.dateTime,
  });

  factory Transaction.fromJson(
      Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      symbol: json['symbol'] ?? '',
      companyName: json['companyName'] ?? '',
      type: json['type'] ?? 'BUY',
      price: double.tryParse(
        json['price']?.toString() ?? '0'
      ) ?? 0,
      quantity: double.tryParse(
        json['quantity']?.toString() ?? '0'
      ) ?? 0,
      totalAmount: double.tryParse(
        json['totalAmount']?.toString() ?? '0'
      ) ?? 0,
      dateTime: json['dateTime'] ?? '',
    );
  }
}