import 'package:telegraph/core/base_command_handler.dart';
import 'package:telegraph/core/utils/command_parser.dart';
import 'package:telegraph/core/utils/response_formatter.dart';
import 'package:telegraph/core/utils/response_codes.dart';
import 'package:telegraph/core/utils/formatters.dart';
import 'package:telegraph/core/utils/datetime_logic.dart';
import 'package:telegraph/features/time/services/time_database_service.dart';
import 'package:telegraph/features/time/utils/time_formatter.dart';

class TimeCommandHandler extends BaseCommandHandler {
  final TimeDatabaseService dbService;
  TimeCommandHandler(this.dbService, {super.clock});

  @override
  String get moduleKey => 'time';

  @override
  Future<String> handle(String input) async {
    final raw = input.toLowerCase().trim();
    if (raw.startsWith("$moduleKey start")) return await _handleStart(input);
    if (raw.startsWith("$moduleKey log")) return await _handleLog(input);
    if (raw == "$moduleKey stop") return await _handleStop();
    if (raw == "$moduleKey status") return await _handleStatus();
    if (raw.startsWith("$moduleKey delete")) {
      return performDelete(input, dbService.deleteSession);
    }
    if (raw.startsWith("$moduleKey list")) return await _handleList(input);
    if (raw.startsWith("$moduleKey summary")) {
      return await _handleSummary(input);
    }
    if (raw.startsWith("$moduleKey stats")) {
      return await _handleHourlyStats(input);
    }
    return unknownSubCommand();
  }

  @override
  String get helpText =>
      "**Time Tracking:**\n- `time start [\"Note\"] #tags`\n- `time log [date] [range|duration] [\"Note\"] #tags`\n- `time stop` | `time list [date] [#tag]`";

  Future<String> _handleStart(String input) async {
    if (await dbService.getActiveSession() != null) {
      return ResponseFormatter.error(
        "Already active.",
        errorCode: ErrorCode.alreadyActive,
      );
    }
    final cmd = ParsedCommand.parse(input, clock: clock);
    final now = clock();
    await dbService.startSession(cmd.notes, cmd.tags, startTime: now);
    return ResponseFormatter.success(
      "Session Started",
      successCode: SuccessCode.sessionStarted,
      data: {
        "notes": cmd.notes.isEmpty ? "(no note)" : cmd.notes,
        "tags": cmd.tags.map((t) => '#$t').toList(),
        "at": Formatters.formatTime(now),
      },
    );
  }

  Future<String> _handleStop() async {
    final now = clock();
    final session = await dbService.stopSession(stopTime: now);
    if (session == null) {
      return ResponseFormatter.error(
        "No active session.",
        errorCode: ErrorCode.noActiveSession,
      );
    }
    return ResponseFormatter.success(
      "Session Stopped",
      successCode: SuccessCode.sessionStopped,
      data: {
        "notes": session.notes.isEmpty ? "(no note)" : session.notes,
        "duration": Formatters.formatDuration(
          now.difference(session.startTime).inMinutes.toDouble(),
        ),
      },
    );
  }

  Future<String> _handleStatus() async {
    final active = await dbService.getActiveSession();
    if (active == null) return "😴 **Status:** Idle";
    return ResponseFormatter.format("🕒 **Tracking**", {
      "notes": active.notes.isEmpty ? "(no note)" : active.notes,
      "elapsed": "${clock().difference(active.startTime).inMinutes}m",
    });
  }

  /// ✅ Fixed: Now handles tag filter
  Future<String> _handleList(String input) async {
    final cmd = ParsedCommand.parse(input, clock: clock);
    final date = cmd.date ?? clock();
    final tagFilter = cmd.tags.isNotEmpty ? cmd.tags.first : null;

    final sessions = await dbService.getSessions(date: date, tag: tagFilter);

    if (sessions.isEmpty) {
      String msg = "📅 Empty for ${Formatters.formatDate(date)}";
      if (tagFilter != null) msg += " with tag #$tagFilter";
      return "$msg.";
    }
    return TimeFormatter.formatSessionListJson(date, sessions);
  }

  Future<String> _handleSummary(String input) async {
    final cmd = ParsedCommand.parse(input, clock: clock);
    final date = cmd.date ?? clock();
    final sessions = await dbService.getSessions(date: date);
    final tags = await dbService.getTagWiseSummary(date: date);
    final hourly = await dbService.getHourlyDistribution(date: date);
    final totalMins = sessions.fold(
      0.0,
      (sum, s) =>
          sum + (s.endTime ?? clock()).difference(s.startTime).inMinutes,
    );
    return TimeFormatter.formatDailySummaryJson(
      date: date,
      totalMinutes: totalMins,
      sessionCount: sessions.length,
      tags: tags,
      hourlyData: hourly,
    );
  }

  Future<String> _handleHourlyStats(String input) async {
    final cmd = ParsedCommand.parse(input, clock: clock);
    final data = await dbService.getHourlyDistribution(
      date: cmd.date ?? clock(),
    );
    return TimeFormatter.formatHourlyStatsJson(
      cmd.date ?? clock(),
      data.where((e) => (e['total_minutes'] ?? 0) > 0).toList(),
    );
  }

  Future<String> _handleLog(String input) async {
    final cmd = ParsedCommand.parse(input, clock: clock);
    if (cmd.timeRange == null && cmd.duration == null) {
      return ResponseFormatter.error(
        "Format: `time log [date] [HH:mm-HH:mm|duration] [\"Note\"] #tags`",
        errorCode: ErrorCode.invalidFormat,
      );
    }
    final date = cmd.date ?? clock();
    DateTime start;
    DateTime end;
    if (cmd.timeRange != null) {
      final range = DateTimeLogic.parseCompactRange(date, cmd.timeRange!);
      if (range == null) {
        return ResponseFormatter.error(
          "Invalid range format. Use HH:mm-HH:mm",
          errorCode: ErrorCode.timeParseError,
        );
      }
      start = range.keys.first;
      end = range.values.first;
    } else {
      end = DateTimeLogic.isSameDay(date, clock())
          ? clock()
          : DateTime(date.year, date.month, date.day, 23, 59);
      start = end.subtract(cmd.duration!);
    }
    await dbService.recordCompletedSession(
      start: start,
      end: end,
      notes: cmd.notes,
      tags: cmd.tags,
    );
    return ResponseFormatter.success(
      "Logged",
      successCode: SuccessCode.sessionLogged,
      data: {
        "duration": Formatters.formatDuration(
          end.difference(start).inMinutes.toDouble(),
        ),
        "period":
            "${Formatters.formatShortTime(start)}-${Formatters.formatShortTime(end)}",
        "notes": cmd.notes.isEmpty ? "(no note)" : cmd.notes,
        "tags": cmd.tags.map((t) => '#$t').toList(),
      },
    );
  }
}
