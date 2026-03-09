enum TransactionType { income, expense }

class FinanceTransaction {
  final int? id;
  final TransactionType type;
  final double amount;
  final String transactionTime;
  final String? note;

  FinanceTransaction({
    this.id,
    required this.type,
    required this.amount,
    required this.transactionTime,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'transaction_time': transactionTime,
      'note': note,
    };
  }

  factory FinanceTransaction.fromMap(Map<String, dynamic> map) {
    return FinanceTransaction(
      id: map['id'],
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.income,
      ),
      amount: map['amount'].toDouble(),
      transactionTime: map['transaction_time'],
      note: map['note'],
    );
  }

  FinanceTransaction copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    String? transactionTime,
    String? note,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      transactionTime: transactionTime ?? this.transactionTime,
      note: note ?? this.note,
    );
  }
}
