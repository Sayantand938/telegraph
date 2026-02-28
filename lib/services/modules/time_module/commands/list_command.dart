// lib/services/modules/time_module/commands/list_command.dart
import '../utils/time_utils.dart';
import '../../../database/database_helper.dart';

class ListCommand {
  final DatabaseHelper _db;

  ListCommand(this._db);

  Future<String> execute() async {
    // 1. Fetch all sessions (consider adding an 'ORDER BY start_time DESC' in your helper)
    final sessions = await _db.querySessions();

    if (sessions.isEmpty) {
      return '📋 **No Sessions**\n'
          '* No time sessions recorded yet.';
    }

    final buffer = StringBuffer();
    buffer.writeln('📋 **Time Sessions** (${sessions.length} total)\n');

    for (int i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      final isActive = s['is_active'] == 1;
      final status = isActive ? '🟢 Active' : '⚪ Completed';

      final start = DateTime.parse(s['start_time']);
      final end = s['end_time'] != null
          ? DateTime.parse(s['end_time'])
          : DateTime.now();

      // Ensure duration isn't negative due to clock sync issues
      final diff = end.isAfter(start) ? end.difference(start) : Duration.zero;
      final duration = formatDuration(diff);

      // Using a numbered list for sessions with nested bullets
      buffer.writeln('${i + 1}. **${s['note']}**');
      buffer.writeln('   * **ID:** `${s['id']}` | $status');
      buffer.writeln(
        '   * **Time:** ${formatDateTime(start)} — ${s['end_time'] != null ? formatDateTime(end) : "_Now_"}',
      );
      buffer.writeln('   * **Duration:** $duration\n');
    }

    buffer.writeln('---');
    return buffer.toString().trim();
  }
}
