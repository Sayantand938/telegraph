// lib/services/modules/time_module/commands/list_command.dart
import '../utils/time_utils.dart';
import '../../../database/database_helper.dart';

class ListCommand {
  final DatabaseHelper _db;

  ListCommand(this._db);

  Future<String> execute(String source) async {
    final sessions = await _db.querySessions();

    if (sessions.isEmpty) {
      return '📋 **No Sessions**\n\n'
          '* No time sessions recorded yet.\n'
          '* **Source:** $source';
    }

    final buffer = StringBuffer();
    buffer.writeln('📋 **Time Sessions** (${sessions.length} total)\n');

    for (int i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      final status = s['is_active'] == 1 ? '🟢 Active' : '⚪ Completed';

      final start = DateTime.parse(s['start_time']);
      final end = s['end_time'] != null
          ? DateTime.parse(s['end_time'])
          : DateTime.now();

      final duration = formatDuration(end.difference(start));

      // Using a numbered list for the sessions, with nested bullets for details
      buffer.writeln('${i + 1}. **${s['note']}**');
      buffer.writeln('   * **ID:** `${s['id']}` | $status');
      buffer.writeln(
        '   * **Time:** ${formatDateTime(start)} — ${s['end_time'] != null ? formatDateTime(end) : "_Now_"}',
      );
      buffer.writeln('   * **Duration:** $duration\n');
    }

    buffer.writeln('---');
    buffer.writeln('* **Source:** $source');

    return buffer.toString();
  }
}
