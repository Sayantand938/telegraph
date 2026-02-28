import 'base_module.dart';
import '../database/database_helper.dart';

/// Time Module with SQLite persistence
class TimeModule extends BaseModule {
  TimeModule() : super('time');
  final DatabaseHelper _db = DatabaseHelper();

  // ✅ Removed unnecessary init() override since it just calls super.init()

  @override
  Future<String?> handle(Map<String, dynamic> data, DateTime timestamp) async {
    incrementCommand();
    final action = data['action'] as String?;
    final source = data['source'] ?? 'manual';

    switch (action) {
      case 'start':
        return await _handleStart(data, timestamp, source);
      case 'stop':
        return await _handleStop(data, timestamp, source);
      case 'add':
        return await _handleAdd(data, timestamp, source);
      case 'status':
        return await _handleStatus(source);
      case 'list':
        return await _handleList(source);
      default:
        return '❌ Unknown action: "$action". Try: start, stop, add, status, list\n• Source: $source';
    }
  }

  /// ✅ START ACTION
  Future<String> _handleStart(
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
      return '⚠️ **Cannot Start**\n'
          '• You already have an active session: "${s['note']}"\n'
          '• Started at: ${_formatDateTime(DateTime.parse(s['start_time']))}\n'
          '• Please stop it first with: `@time --action stop`\n'
          '• Source: $source';
    }

    final note = data['note'] as String? ?? 'Untitled Session';
    final tags = _parseTags(data['tags']);
    final id = _generateId();

    // 2. Check for overlap
    final overlap = await _checkOverlap(timestamp, null, note);
    if (overlap != null) {
      return '⚠️ **Overlap Detected**\n'
          '• Cannot start session: "$note"\n'
          '• Overlaps with: "${overlap['note']}"\n'
          '• Time: ${_formatDateTime(DateTime.parse(overlap['start_time']))} - ${overlap['end_time'] != null ? _formatDateTime(DateTime.parse(overlap['end_time'])) : "Active"}\n'
          '• Source: $source';
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

    return '⏱️ **Timer Started**\n'
        '• ID: $id\n'
        '• Note: $note\n'
        '• Tags: ${tags.isNotEmpty ? tags.join(", ") : "none"}\n'
        '• Started: ${_formatDateTime(timestamp)}\n'
        '• Source: $source';
  }

  /// ✅ STOP ACTION
  Future<String> _handleStop(
    Map<String, dynamic> data,
    DateTime timestamp,
    String source,
  ) async {
    // 1. Check for active session
    final activeSessions = await _db.querySessions(
      where: 'is_active = ?',
      whereArgs: [1],
    );
    if (activeSessions.isEmpty) {
      return '⚠️ **No Active Session**\n'
          '• Cannot stop - no timer is running\n'
          '• Start one with: `@time --action start --note "Work"`\n'
          '• Source: $source';
    }

    final session = activeSessions.first;
    final startTime = DateTime.parse(session['start_time']);
    final endTime = timestamp;

    // 2. Validate endtime > starttime
    if (endTime.isBefore(startTime) || endTime.isAtSameMomentAs(startTime)) {
      return '❌ **Invalid Time**\n'
          '• End time must be after start time\n'
          '• Start: ${_formatDateTime(startTime)}\n'
          '• End: ${_formatDateTime(endTime)}\n'
          '• Source: $source';
    }

    // 3. Check overnight split
    final spansOvernight =
        startTime.day != endTime.day ||
        startTime.month != endTime.month ||
        startTime.year != endTime.year;

    if (spansOvernight) {
      return await _handleOvernightSplit(session, endTime, source);
    }

    // 4. Normal stop
    await _db.updateSession(session['id'], {
      'end_time': endTime.toIso8601String(),
      'is_active': 0,
    });

    final duration = endTime.difference(startTime);
    return '⏹️ **Timer Stopped**\n'
        '• ID: ${session['id']}\n'
        '• Note: ${session['note']}\n'
        '• Duration: ${_formatDuration(duration)}\n'
        '• Start: ${_formatDateTime(startTime)}\n'
        '• End: ${_formatDateTime(endTime)}\n'
        '• Source: $source';
  }

  /// ✅ ADD ACTION (Manual Entry)
  Future<String> _handleAdd(
    Map<String, dynamic> data,
    DateTime timestamp,
    String source,
  ) async {
    final startTimeStr = data['start_time'] as String?;
    final endTimeStr = data['end_time'] as String?;

    if (startTimeStr == null || endTimeStr == null) {
      return '❌ **Missing Time Data**\n'
          '• Please provide: --start_time "YYYY-MM-DD HH:MM" --end_time "YYYY-MM-DD HH:MM"\n'
          '• Source: $source';
    }

    DateTime startTime;
    DateTime endTime;
    try {
      startTime = DateTime.parse(startTimeStr);
      endTime = DateTime.parse(endTimeStr);
    } catch (e) {
      return '❌ **Invalid Time Format**\n• Use format: "YYYY-MM-DD HH:MM"\n• Source: $source';
    }

    if (endTime.isBefore(startTime) || endTime.isAtSameMomentAs(startTime)) {
      return '❌ **Invalid Time Range**\n• End time must be after start time\n• Source: $source';
    }

    final note = data['note'] as String? ?? 'Manual Entry';
    final tags = _parseTags(data['tags']);
    final id = _generateId();

    // Check overlap
    final overlap = await _checkOverlap(startTime, endTime, note);
    if (overlap != null) {
      return '⚠️ **Overlap Detected**\n• Overlaps with: "${overlap['note']}"\n• Source: $source';
    }

    // Check overnight
    final spansOvernight =
        startTime.day != endTime.day ||
        startTime.month != endTime.month ||
        startTime.year != endTime.year;

    if (spansOvernight) {
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
    return '➕ **Session Added**\n'
        '• ID: $id\n• Note: $note\n• Duration: ${_formatDuration(duration)}\n'
        '• Start: ${_formatDateTime(startTime)}\n• End: ${_formatDateTime(endTime)}\n'
        '• Source: $source';
  }

  /// ✅ STATUS ACTION
  Future<String> _handleStatus(String source) async {
    final activeSessions = await _db.querySessions(
      where: 'is_active = ?',
      whereArgs: [1],
    );
    if (activeSessions.isEmpty) {
      return '⏱️ **No Active Session**\n• All timers are stopped\n• Source: $source';
    }

    final session = activeSessions.first;
    final startTime = DateTime.parse(session['start_time']);
    final duration = DateTime.now().difference(startTime);

    return '⏱️ **Active Session**\n'
        '• ID: ${session['id']}\n• Note: ${session['note']}\n'
        '• Started: ${_formatDateTime(startTime)}\n'
        '• Running for: ${_formatDuration(duration)}\n• Source: $source';
  }

  /// ✅ LIST ACTION
  Future<String> _handleList(String source) async {
    final sessions = await _db.querySessions();
    if (sessions.isEmpty) {
      return '📋 **No Sessions**\n• No time sessions recorded yet\n• Source: $source';
    }

    final buffer = StringBuffer();
    buffer.writeln('📋 **Time Sessions** (${sessions.length} total)');
    buffer.writeln('');

    for (int i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      final status = s['is_active'] == 1 ? '🟢 Active' : '⚪ Completed';
      final start = DateTime.parse(s['start_time']);
      final end = s['end_time'] != null
          ? DateTime.parse(s['end_time'])
          : DateTime.now();
      final duration = _formatDuration(end.difference(start));

      buffer.writeln('${i + 1}. ${s['note']}');
      buffer.writeln('   • ID: ${s['id']} | $status');
      buffer.writeln(
        '   • ${_formatDateTime(start)} - ${s['end_time'] != null ? _formatDateTime(end) : "Now"}',
      );
      buffer.writeln('   • Duration: $duration');
      buffer.writeln('');
    }

    buffer.writeln('• Source: $source');
    return buffer.toString();
  }

  /// 🔀 Overnight Split (Stop)
  Future<String> _handleOvernightSplit(
    Map<String, dynamic> session,
    DateTime endTime,
    String source,
  ) async {
    final startTime = DateTime.parse(session['start_time']);
    final sessionsCreated = <Map<String, dynamic>>[];

    var currentDate = DateTime(startTime.year, startTime.month, startTime.day);
    var currentTime = startTime;

    while (currentDate.isBefore(endTime) ||
        currentDate.isAtSameMomentAs(endTime)) {
      final nextDay = currentDate.add(const Duration(days: 1));
      final sessionEnd = nextDay.isBefore(endTime) ? nextDay : endTime;

      if (sessionEnd.isAfter(currentTime)) {
        final id = _generateId();
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

      currentDate = nextDay;
      currentTime = nextDay;
    }

    // Delete original active session
    await _db.deleteSession(session['id']);

    // Insert split sessions
    for (final s in sessionsCreated) {
      await _db.insertSession(s);
    }

    final totalDuration = sessionsCreated.fold<Duration>(
      Duration.zero,
      (sum, s) =>
          sum +
          (DateTime.parse(
            s['end_time'],
          ).difference(DateTime.parse(s['start_time']))),
    );

    return '🌙 **Overnight Session Split**\n'
        '• Original: ${session['note']}\n• Split into: ${sessionsCreated.length} session(s)\n'
        '• Total Duration: ${_formatDuration(totalDuration)}\n• Source: $source';
  }

  /// 🔀 Overnight Split (Add)
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

    while (currentDate.isBefore(endTime) ||
        currentDate.isAtSameMomentAs(endTime)) {
      final nextDay = currentDate.add(const Duration(days: 1));
      final sessionEnd = nextDay.isBefore(endTime) ? nextDay : endTime;

      if (sessionEnd.isAfter(currentTime)) {
        final id = _generateId();
        sessionsCreated.add({
          'id': id,
          'start_time': currentTime.toIso8601String(),
          'end_time': sessionEnd.toIso8601String(),
          'note': '$note (Day ${sessionsCreated.length + 1})',
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

    final totalDuration = sessionsCreated.fold<Duration>(
      Duration.zero,
      (sum, s) =>
          sum +
          (DateTime.parse(
            s['end_time'],
          ).difference(DateTime.parse(s['start_time']))),
    );

    return '🌙 **Overnight Session Split**\n'
        '• Original: $note\n• Split into: ${sessionsCreated.length} session(s)\n'
        '• Total Duration: ${_formatDuration(totalDuration)}\n• Source: $source';
  }

  /// 🔍 Overlap Check
  Future<Map<String, dynamic>?> _checkOverlap(
    DateTime newStart,
    DateTime? newEnd,
    String newNote,
  ) async {
    final sessions = await _db.querySessions();

    for (final s in sessions) {
      // Skip same session
      if (s['note'] == newNote &&
          s['start_time'] == newStart.toIso8601String()) {
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

  /// Helpers
  List<String> _parseTags(dynamic tags) {
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

  String _generateId() =>
      'T${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

  String _formatDateTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes.remainder(60)).toString().padLeft(2, '0');
    final s = (d.inSeconds.remainder(60)).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Map<String, dynamic> getStats() {
    final baseStats = super.getStats();
    return {...baseStats, 'storage': 'SQLite'};
  }
}
