class TransactionModel {
  final int? id;
  final double amount;
  final String type; // 'income' or 'expense'
  final DateTime date;
  final String notes;
  final List<String> tags;
  final List<String> participants;

  TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.notes,
    required this.tags,
    required this.participants,
  });

  List<String> get displayTags =>
      tags.map((t) => t.startsWith('#') ? t : '#$t').toList();
  List<String> get displayParticipants =>
      participants.map((p) => p.startsWith('@') ? p : '@$p').toList();

  factory TransactionModel.fromMap(
    Map<String, dynamic> map, {
    List<String> tags = const [],
    List<String> participants = const [],
  }) {
    return TransactionModel(
      id: map['id'] as int?,
      amount: map['amount'] as double,
      type: map['type'] as String,
      date: DateTime.parse(map['transaction_date'] as String),
      notes: map['notes'] as String? ?? '',
      tags: tags,
      participants: participants,
    );
  }
}
