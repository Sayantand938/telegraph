// lib/services/modules/time_module/commands/status_command.dart
import '../utils/time_utils.dart';
import '../../../database/database_helper.dart';

class StatusCommand {
  final DatabaseHelper _db;

  StatusCommand(this._db);

  Future<String> execute(String source) async {
    final activeSessions = await _db.querySessions(
      where: 'is_active = ?',
      whereArgs: [1],
    );

    if (activeSessions.isEmpty) {
      return '⏱️ **No Active Session**\n\n'
          '* All timers are currently stopped.\n'
          '* **Source:** $source';
    }

    final session = activeSessions.first;
    final startTime = DateTime.parse(session['start_time']);
    final duration = DateTime.now().difference(startTime);

    return '⏱️ **Active Session**\n\n'
        '* **ID:** `${session['id']}`\n'
        '* **Note:** ${session['note']}\n'
        '* **Started:** ${formatDateTime(startTime)}\n'
        '* **Running For:** ${formatDuration(duration)}\n'
        '* **Source:** $source';
  }
}
