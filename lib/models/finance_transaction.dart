enum TransactionType { income, expense }

class FinanceTransaction {
  final int? id;
  final TransactionType type;
  final double amount;
  final String eventTimestamp;
  final String? note;

  FinanceTransaction({
    this.id,
    required this.type,
    required this.amount,
    required this.eventTimestamp,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'event_timestamp': eventTimestamp,
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
      eventTimestamp: map['event_timestamp'],
      note: map['note'],
    );
  }

  FinanceTransaction copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    String? eventTimestamp,
    String? note,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      eventTimestamp: eventTimestamp ?? this.eventTimestamp,
      note: note ?? this.note,
    );
  }
}
