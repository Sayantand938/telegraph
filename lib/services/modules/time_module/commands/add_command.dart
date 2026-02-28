// lib/services/modules/time_module/commands/add_command.dart
import '../utils/time_utils.dart';
import '../../../database/database_helper.dart';

class AddCommand {
  final DatabaseHelper _db;

  AddCommand(this._db);

  Future<String> execute(
    Map<String, dynamic> data,
    DateTime timestamp,
    String source,
  ) async {
    final startTimeStr = data['start_time'] as String?;
    final endTimeStr = data['end_time'] as String?;

    if (startTimeStr == null || endTimeStr == null) {
      return '❌ **Missing Time Data**\n\n'
          '* **Required:** `--start_time "YYYY-MM-DD HH:MM"`\n'
          '* **Required:** `--end_time "YYYY-MM-DD HH:MM"`\n'
          '* **Source:** $source';
    }

    DateTime startTime;
    DateTime endTime;
    try {
      startTime = DateTime.parse(startTimeStr);
      endTime = DateTime.parse(endTimeStr);
    } catch (e) {
      return '❌ **Invalid Time Format**\n\n'
          '* **Format:** Use `"YYYY-MM-DD HH:MM"`\n'
          '* **Source:** $source';
    }

    if (endTime.isBefore(startTime) || endTime.isAtSameMomentAs(startTime)) {
      return '❌ **Invalid Time Range**\n\n'
          '* **Error:** End time must be after start time.\n'
          '* **Source:** $source';
    }

    final note = data['note'] as String? ?? 'Manual Entry';
    final tags = parseTags(data['tags']);
    final id = generateId();

    // Check overlap
    final overlap = await checkOverlap(_db, startTime, endTime, note);
    if (overlap != null) {
      return '⚠️ **Overlap Detected**\n\n'
          '* **Conflict:** "${overlap['note']}"\n'
          '* **Source:** $source';
    }

    // Check overnight
    if (spansOvernight(startTime, endTime)) {
      return await _handleOvernightAdd(startTime, endTime, note, tags, source);
    }

    // Insert
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
    return '➕ **Session Added**\n\n'
        '* **ID:** `$id`\n'
        '* **Note:** $note\n'
        '* **Duration:** ${formatDuration(duration)}\n'
        '* **Start:** ${formatDateTime(startTime)}\n'
        '* **End:** ${formatDateTime(endTime)}\n'
        '* **Source:** $source';
  }

  Future<String> _handleOvernightAdd(
    DateTime startTime,
    DateTime endTime,
    String note,
    List<String> tags,
    String source,
  ) async {
    final sessionsCreated = <Map<String, dynamic>>[];
    var currentDate = DateTime(startTime.year, startTime.month, startTime.day);
    var currentTime = startTime;

    while (currentDate.isBefore(endTime)) {
      final nextDay = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day + 1,
      );
      final sessionEnd = nextDay.isBefore(endTime) ? nextDay : endTime;

      if (sessionEnd.isAfter(currentTime)) {
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
      }
      currentDate = nextDay;
      currentTime = nextDay;
    }

    for (final s in sessionsCreated) {
      await _db.insertSession(s);
    }

    final totalDuration = endTime.difference(startTime);

    return '🌙 **Overnight Session Split**\n\n'
        '* **Original Note:** $note\n'
        '* **Splits:** Created ${sessionsCreated.length} daily entries\n'
        '* **Total Duration:** ${formatDuration(totalDuration)}\n'
        '* **Source:** $source';
  }
}
