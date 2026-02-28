// lib/services/modules/time_module/commands/add_command.dart
import '../utils/time_utils.dart';
import '../../../database/database_helper.dart';

class AddCommand {
  final DatabaseHelper _db;

  AddCommand(this._db);

  Future<String> execute(Map<String, dynamic> data, DateTime timestamp) async {
    final startTimeStr = data['start_time'] as String?;
    final endTimeStr = data['end_time'] as String?;

    if (startTimeStr == null || endTimeStr == null) {
      return '❌ **Missing Time Data**\n'
          '* **Required:** `--start_time "YYYY-MM-DD HH:MM"`\n'
          '* **Required:** `--end_time "YYYY-MM-DD HH:MM"`';
    }

    DateTime startTime;
    DateTime endTime;

    try {
      startTime = DateTime.parse(startTimeStr);
      endTime = DateTime.parse(endTimeStr);
    } catch (e) {
      return '❌ **Invalid Time Format**\n'
          '* **Format:** Use `"YYYY-MM-DD HH:MM"`';
    }

    if (endTime.isBefore(startTime) || endTime.isAtSameMomentAs(startTime)) {
      return '❌ **Invalid Time Range**\n'
          '* **Error:** End time must be after start time.';
    }

    final note = data['note'] as String? ?? 'Manual Entry';
    final tags = parseTags(data['tags']);
    final id = generateId();

    // Check overlap
    final overlap = await checkOverlap(_db, startTime, endTime, note);
    if (overlap != null) {
      return '⚠️ **Overlap Detected**\n'
          '* **Conflict:** "${overlap['note']}"';
    }

    // Check overnight
    if (spansOvernight(startTime, endTime)) {
      return await _handleOvernightAdd(startTime, endTime, note, tags);
    }

    // Insert single session
    await _db.insertSession({
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'note': note,
      'tags': tags.join(','),
      'is_active': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    final duration = endTime.difference(startTime);
    return '➕ **Session Added**\n'
        '* **ID:** `$id`\n'
        '* **Note:** $note\n'
        '* **Duration:** ${formatDuration(duration)}\n'
        '* **Start:** ${formatDateTime(startTime)}\n'
        '* **End:** ${formatDateTime(endTime)}';
  }

  Future<String> _handleOvernightAdd(
    DateTime startTime,
    DateTime endTime,
    String note,
    List<String> tags,
  ) async {
    final sessionsCreated = <Map<String, dynamic>>[];
    var currentTime = startTime;

    while (currentTime.isBefore(endTime)) {
      // Calculate the start of the next day (midnight)
      final nextDay = DateTime(
        currentTime.year,
        currentTime.month,
        currentTime.day + 1,
      );

      // The session ends at either the next midnight or the final end time
      final sessionEnd = nextDay.isBefore(endTime) ? nextDay : endTime;

      final id = generateId();
      sessionsCreated.add({
        'id': id,
        'start_time': currentTime.toIso8601String(),
        'end_time': sessionEnd.toIso8601String(),
        'note': '$note (Part ${sessionsCreated.length + 1})',
        'tags': tags.join(','),
        'is_active': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Advance currentTime to the start of the next segment
      currentTime = nextDay;
    }

    for (final s in sessionsCreated) {
      await _db.insertSession(s);
    }

    final totalDuration = endTime.difference(startTime);
    return '🌙 **Overnight Session Split**\n'
        '* **Original Note:** $note\n'
        '* **Splits:** Created ${sessionsCreated.length} daily entries\n'
        '* **Total Duration:** ${formatDuration(totalDuration)}';
  }
}
