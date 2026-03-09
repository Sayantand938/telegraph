class Session {
  final int? id;
  final String startTime;
  final String? endTime;
  final String? notes;

  Session({this.id, required this.startTime, this.endTime, this.notes});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime,
      'end_time': endTime,
      'notes': notes,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      notes: map['notes'],
    );
  }

  Session copyWith({
    int? id,
    String? startTime,
    String? endTime,
    String? notes,
  }) {
    return Session(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          notes == other.notes;

  @override
  int get hashCode =>
      id.hashCode ^ startTime.hashCode ^ endTime.hashCode ^ notes.hashCode;
}
