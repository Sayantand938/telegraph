// lib/services/modules/time_module/utils/time_utils.dart
import '../../../database/database_helper.dart';

/// Parse tags from various input types
List<String> parseTags(dynamic tags) {
  if (tags == null) return [];
  if (tags is List) {
    return tags
        .map((t) => t.toString().trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }
  if (tags is String) {
    return tags
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }
  return [];
}

/// Generate a unique session ID
String generateId() =>
    'T${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

/// Format DateTime to DD/MM HH:mm
String formatDateTime(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

/// Format Duration to HH:mm:ss
String formatDuration(Duration d) {
  final h = d.inHours.toString().padLeft(2, '0');
  final m = (d.inMinutes.remainder(60)).toString().padLeft(2, '0');
  final s = (d.inSeconds.remainder(60)).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

/// Check if a new session overlaps with existing sessions
Future<Map<String, dynamic>?> checkOverlap(
  DatabaseHelper db,
  DateTime newStart,
  DateTime? newEnd,
  String newNote,
) async {
  final sessions = await db.querySessions();
  for (final s in sessions) {
    // Skip same session
    if (s['note'] == newNote && s['start_time'] == newStart.toIso8601String()) {
      continue;
    }
    final start = DateTime.parse(s['start_time']);
    final end = s['end_time'] != null
        ? DateTime.parse(s['end_time'])
        : DateTime.now();

    if (newEnd == null) {
      // Starting now: check if newStart is within existing session
      if (newStart.isAfter(start) && newStart.isBefore(end)) {
        return s;
      }
      // Check if existing active session starts after newStart
      if (s['is_active'] == 1 && start.isAfter(newStart)) {
        return s;
      }
    } else {
      // Standard overlap check
      if (newStart.isBefore(end) && newEnd.isAfter(start)) {
        return s;
      }
    }
  }
  return null;
}

/// Check if a time range spans overnight
bool spansOvernight(DateTime start, DateTime end) {
  return start.day != end.day ||
      start.month != end.month ||
      start.year != end.year;
}
