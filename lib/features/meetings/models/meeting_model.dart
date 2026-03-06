class MeetingModel {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final String notes;
  final List<String> tags;
  final List<String> participants;

  MeetingModel({
    this.id,
    required this.startTime,
    this.endTime,
    required this.notes,
    required this.tags,
    required this.participants,
  });

  List<String> get displayTags =>
      tags.map((t) => t.startsWith('#') ? t : '#$t').toList();

  List<String> get displayParticipants =>
      participants.map((p) => p.startsWith('@') ? p : '@$p').toList();

  factory MeetingModel.fromMap(
    Map<String, dynamic> map, {
    List<String> tags = const [],
    List<String> participants = const [],
  }) {
    return MeetingModel(
      id: map['id'] as int?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      notes: map['notes'] as String? ?? '',
      tags: tags,
      participants: participants,
    );
  }

  MeetingModel copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    List<String>? tags,
    List<String>? participants,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      participants: participants ?? this.participants,
    );
  }
}
