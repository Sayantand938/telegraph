class SessionModel {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final String notes;
  final List<String> tags;

  SessionModel({
    this.id,
    required this.startTime,
    this.endTime,
    required this.notes,
    required this.tags,
  });

  // DRY: Centralized tag formatting logic
  List<String> get displayTags =>
      tags.map((t) => t.startsWith('#') ? t : '#$t').toList();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'notes': notes,
    };
  }

  factory SessionModel.fromMap(
    Map<String, dynamic> map, {
    List<String> tags = const [],
  }) {
    return SessionModel(
      id: map['id'] as int?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      notes: map['notes'] as String? ?? '',
      tags: tags,
    );
  }

  SessionModel copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    List<String>? tags,
  }) {
    return SessionModel(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
    );
  }
}
