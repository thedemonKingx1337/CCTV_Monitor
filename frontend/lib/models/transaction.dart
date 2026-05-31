class PosTransaction {
  final String transactionId;
  final String timestamp;
  final double amount;
  final int itemsCount;
  final String zoneId;
  final String paymentMethod;

  PosTransaction({
    required this.transactionId,
    required this.timestamp,
    required this.amount,
    required this.itemsCount,
    required this.zoneId,
    required this.paymentMethod,
  });

  factory PosTransaction.fromJson(Map<String, dynamic> json) {
    return PosTransaction(
      transactionId: json['transaction_id'],
      timestamp: json['timestamp'],
      amount: (json['amount'] as num).toDouble(),
      itemsCount: json['items_count'] as int,
      zoneId: json['zone_id'],
      paymentMethod: json['payment_method'],
    );
  }
}
