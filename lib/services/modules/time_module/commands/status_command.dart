// lib/services/modules/time_module/commands/status_command.dart
import '../utils/time_utils.dart';
import '../../../database/database_helper.dart';

class StatusCommand {
  final DatabaseHelper _db;

  StatusCommand(this._db);

  Future<String> execute() async {
    // 1. Check for active session
    final activeSessions = await _db.querySessions(
      where: 'is_active = ?',
      whereArgs: [1],
    );

    if (activeSessions.isEmpty) {
      return '⏱️ **No Active Session**\n'
          '* All timers are currently stopped.';
    }

    final session = activeSessions.first;
    final startTime = DateTime.parse(session['start_time']);

    // Calculate live duration
    final now = DateTime.now();
    final duration = now.isAfter(startTime)
        ? now.difference(startTime)
        : Duration.zero;

    return '⏱️ **Active Session**\n'
        '* **ID:** `${session['id']}`\n'
        '* **Note:** ${session['note']}\n'
        '* **Started:** ${formatDateTime(startTime)}\n'
        '* **Running For:** ${formatDuration(duration)}';
  }
}
