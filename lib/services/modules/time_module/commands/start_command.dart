// lib/services/modules/time_module/commands/start_command.dart
import '../utils/time_utils.dart';
import '../../../database/database_helper.dart';

class StartCommand {
  final DatabaseHelper _db;

  StartCommand(this._db);

  Future<String> execute(
    Map<String, dynamic> data,
    DateTime timestamp,
    String source,
  ) async {
    // 1. Check for active session
    final activeSessions = await _db.querySessions(
      where: 'is_active = ?',
      whereArgs: [1],
    );

    if (activeSessions.isNotEmpty) {
      final s = activeSessions.first;
      return '⚠️ **Cannot Start Session**\n\n'
          '* **Conflict:** You already have an active session: "${s['note']}"\n'
          '* **Started:** ${formatDateTime(DateTime.parse(s['start_time']))}\n'
          '* **Action:** Please stop it first with `@time --action stop`\n'
          '* **Source:** $source';
    }

    final note = data['note'] as String? ?? 'Untitled Session';
    final tags = parseTags(data['tags']);
    final id = generateId();

    // 2. Check for overlap
    final overlap = await checkOverlap(_db, timestamp, null, note);
    if (overlap != null) {
      final overlapStart = DateTime.parse(overlap['start_time']);
      final overlapEndStr = overlap['end_time'] != null
          ? formatDateTime(DateTime.parse(overlap['end_time']))
          : "Active";

      return '⚠️ **Overlap Detected**\n\n'
          '* **Error:** Cannot start session: "$note"\n'
          '* **Overlaps With:** "${overlap['note']}"\n'
          '* **Interval:** ${formatDateTime(overlapStart)} — $overlapEndStr\n'
          '* **Source:** $source';
    }

    // 3. Insert new session
    await _db.insertSession({
      'id': id,
      'start_time': timestamp.toIso8601String(),
      'end_time': null,
      'note': note,
      'tags': tags.join(','),
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    return '⏱️ **Timer Started**\n\n'
        '* **ID:** `$id`\n'
        '* **Note:** $note\n'
        '* **Tags:** ${tags.isNotEmpty ? tags.join(", ") : "_none_"}\n'
        '* **Started:** ${formatDateTime(timestamp)}\n'
        '* **Source:** $source';
  }
}
