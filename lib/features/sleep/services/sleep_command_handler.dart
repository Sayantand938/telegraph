import 'package:telegraph/core/base_command_handler.dart';
import 'package:telegraph/core/utils/command_parser.dart';
import 'package:telegraph/core/utils/response_formatter.dart';
import 'package:telegraph/core/utils/response_codes.dart';
import 'package:telegraph/core/utils/formatters.dart';
import 'package:telegraph/core/utils/datetime_logic.dart';
import 'package:telegraph/features/sleep/services/sleep_database_service.dart';
import 'package:telegraph/features/sleep/utils/sleep_formatter.dart';

class SleepCommandHandler extends BaseCommandHandler {
  final SleepDatabaseService dbService;

  SleepCommandHandler(this.dbService, {super.clock});

  @override
  String get moduleKey => 'sleep';

  @override
  Future<String> handle(String input) async {
    final raw = input.toLowerCase().trim();
    if (raw.startsWith("$moduleKey start")) return await _handleStart(input);
    if (raw.startsWith("$moduleKey log")) return await _handleLog(input);
    if (raw.startsWith("$moduleKey stop")) return await _handleStop(input);
    if (raw == "$moduleKey status") return await _handleStatus();
    if (raw.startsWith("$moduleKey delete")) {
      return performDelete(input, dbService.deleteSession);
    }
    if (raw.startsWith("$moduleKey list")) return await _handleList(input);
    if (raw.startsWith("$moduleKey summary")) {
      return await _handleSummary(input);
    }
    if (raw.startsWith("$moduleKey stats")) return await _handleStats(input);
    return unknownSubCommand();
  }

  @override
  String get helpText =>
      "**Sleep Tracking:**\n"
      "- `sleep start [\"Note\"] #tags`\n"
      "- `sleep log [date] [HH:mm-HH:mm|duration] [\"Note\"] #tags`\n"
      "- `sleep stop` | `sleep summary` | `sleep list` | `sleep stats`\n";

  Future<String> _handleStart(String input) async {
    if (await dbService.getActiveSession() != null) {
      return ResponseFormatter.error(
        "Already tracking sleep.",
        errorCode: ErrorCode.alreadyActive,
      );
    }
    final cmd = ParsedCommand.parse(input, clock: clock);
    final now = clock();

    await dbService.startSession(cmd.notes, cmd.tags, startTime: now);

    return ResponseFormatter.success(
      "Sleep Tracking Started",
      successCode: SuccessCode.sessionStarted,
      data: {
        "notes": cmd.notes.isEmpty ? "(no note)" : cmd.notes,
        "tags": cmd.tags.map((t) => '#$t').toList(),
        "at": Formatters.formatTime(now),
      },
    );
  }

  Future<String> _handleStop(String input) async {
    final now = clock();
    final session = await dbService.stopSession(stopTime: now);

    if (session == null) {
      return ResponseFormatter.error(
        "No active sleep session.",
        errorCode: ErrorCode.noActiveSession,
      );
    }

    return ResponseFormatter.success(
      "Sleep Logged",
      successCode: SuccessCode.sessionStopped,
      data: {
        "notes": session.notes.isEmpty ? "(no note)" : session.notes,
        "duration": Formatters.formatDuration(
          now.difference(session.startTime).inMinutes.toDouble(),
        ),
        "period":
            "${Formatters.formatShortTime(session.startTime)}-${Formatters.formatShortTime(now)}",
      },
    );
  }

  Future<String> _handleStatus() async {
    final active = await dbService.getActiveSession();
    if (active == null) return "😴 **Status:** Not tracking";
    final elapsed = clock().difference(active.startTime).inMinutes;
    return ResponseFormatter.format("🛏️ **Tracking Sleep**", {
      "notes": active.notes.isEmpty ? "(no note)" : active.notes,
      "elapsed": Formatters.formatDuration(elapsed.toDouble()),
      "since": Formatters.formatShortTime(active.startTime),
    });
  }

  Future<String> _handleList(String input) async {
    final cmd = ParsedCommand.parse(input, clock: clock);
    final sessions = await dbService.getSessionsByDate(cmd.date ?? clock());
    return sessions.isEmpty
        ? "📅 No sleep records."
        : SleepFormatter.formatSessionListJson(cmd.date ?? clock(), sessions);
  }

  Future<String> _handleSummary(String input) async {
    final cmd = ParsedCommand.parse(input, clock: clock);
    final date = cmd.date ?? clock();
    final summary = await dbService.getSleepSummary(date: date);
    final tags = await dbService.getTagWiseSummary(date: date);
    final stats = summary.first;
    return SleepFormatter.formatDailySummaryJson(
      date: date,
      totalMinutes: stats['total_minutes'],
      sessionCount: stats['session_count'],
      avgMinutes: stats['avg_minutes'],
      tags: tags,
    );
  }

  Future<String> _handleStats(String input) async {
    final cmd = ParsedCommand.parse(input, clock: clock);
    final sessions = await dbService.getSessionsByDate(cmd.date ?? clock());
    if (sessions.isEmpty) return "📊 No stats available.";
    final durations = sessions
        .where((s) => s.endTime != null)
        .map((s) => s.endTime!.difference(s.startTime).inMinutes.toDouble())
        .toList();
    final avgSleep = durations.isEmpty
        ? 0.0
        : durations.reduce((a, b) => a + b) / durations.length;

    return SleepFormatter.formatStatsJson(
      period: Formatters.formatDate(cmd.date ?? clock()),
      avgSleepMinutes: avgSleep,
      bestSleepMinutes: durations.isEmpty
          ? 0.0
          : durations.reduce((a, b) => a > b ? a : b),
      worstSleepMinutes: durations.isEmpty
          ? 0.0
          : durations.reduce((a, b) => a < b ? a : b),
      totalSessions: sessions.length,
    );
  }

  Future<String> _handleLog(String input) async {
    final cmd = ParsedCommand.parse(input, clock: clock);
    if (cmd.timeRange == null && cmd.duration == null) {
      return ResponseFormatter.error(
        "Format: `sleep log [date] [HH:mm-HH:mm|duration] [\"Note\"] #tags`",
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
      "Sleep Logged",
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
