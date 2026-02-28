// lib/services/modules/time_module/commands/stop_command.dart
import '../utils/time_utils.dart';
import '../../../database/database_helper.dart';

class StopCommand {
  final DatabaseHelper _db;

  StopCommand(this._db);

  Future<String> execute(Map<String, dynamic> data, DateTime timestamp) async {
    // 1. Check for active session
    final activeSessions = await _db.querySessions(
      where: 'is_active = ?',
      whereArgs: [1],
    );

    if (activeSessions.isEmpty) {
      return '⚠️ **No Active Session**\n'
          '* **Error:** Cannot stop — no timer is currently running.\n'
          '* **Action:** Start one with: `@time --action start --note "Work"`';
    }

    final session = activeSessions.first;
    final startTime = DateTime.parse(session['start_time']);
    final endTime = timestamp;

    // 2. Validate endtime > starttime
    if (endTime.isBefore(startTime) || endTime.isAtSameMomentAs(startTime)) {
      return '❌ **Invalid Time**\n'
          '* **Error:** End time must be after start time.\n'
          '* **Start:** ${formatDateTime(startTime)}\n'
          '* **End:** ${formatDateTime(endTime)}';
    }

    // 3. Check overnight split
    if (spansOvernight(startTime, endTime)) {
      return await _handleOvernightSplit(session, endTime);
    }

    // 4. Normal stop
    await _db.updateSession(session['id'], {
      'end_time': endTime.toIso8601String(),
      'is_active': 0,
    });

    final duration = endTime.difference(startTime);
    return '⏹️ **Timer Stopped**\n'
        '* **ID:** `${session['id']}`\n'
        '* **Note:** ${session['note']}\n'
        '* **Duration:** ${formatDuration(duration)}\n'
        '* **Start:** ${formatDateTime(startTime)}\n'
        '* **End:** ${formatDateTime(endTime)}';
  }

  Future<String> _handleOvernightSplit(
    Map<String, dynamic> session,
    DateTime endTime,
  ) async {
    final startTime = DateTime.parse(session['start_time']);
    final sessionsCreated = <Map<String, dynamic>>[];
    var currentTime = startTime;

    while (currentTime.isBefore(endTime)) {
      final nextDay = DateTime(
        currentTime.year,
        currentTime.month,
        currentTime.day + 1,
      );

      final sessionEnd = nextDay.isBefore(endTime) ? nextDay : endTime;

      if (sessionEnd.isAfter(currentTime)) {
        final id = generateId();
        sessionsCreated.add({
          'id': id,
          'start_time': currentTime.toIso8601String(),
          'end_time': sessionEnd.toIso8601String(),
          'note': '${session['note']} (Day ${sessionsCreated.length + 1})',
          'tags': session['tags'],
          'is_active': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      currentTime = nextDay;
    }

    // Delete original active session and insert splits
    await _db.deleteSession(session['id']);

    for (final s in sessionsCreated) {
      await _db.insertSession(s);
    }

    final totalDuration = endTime.difference(startTime);
    return '🌙 **Overnight Session Split**\n'
        '* **Original:** ${session['note']}\n'
        '* **Splits:** Created ${sessionsCreated.length} daily entries\n'
        '* **Total Duration:** ${formatDuration(totalDuration)}';
  }
}
