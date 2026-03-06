class TaskModel {
  final int? id;
  final String notes;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final List<String> tags;
  final List<String> participants;

  TaskModel({
    this.id,
    required this.notes,
    this.isCompleted = false,
    required this.createdAt,
    this.dueDate,
    this.completedAt,
    required this.tags,
    required this.participants,
  });

  List<String> get displayTags =>
      tags.map((t) => t.startsWith('#') ? t : '#$t').toList();
  List<String> get displayParticipants =>
      participants.map((p) => p.startsWith('@') ? p : '@$p').toList();

  factory TaskModel.fromMap(
    Map<String, dynamic> map, {
    List<String> tags = const [],
    List<String> participants = const [],
  }) {
    return TaskModel(
      id: map['id'] as int?,
      notes: map['notes'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      tags: tags,
      participants: participants,
    );
  }
}
