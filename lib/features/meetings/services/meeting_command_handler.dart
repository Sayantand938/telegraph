import 'package:telegraph/core/base_command_handler.dart';
import 'package:telegraph/core/utils/command_parser.dart';
import 'package:telegraph/core/utils/response_formatter.dart';
import 'package:telegraph/core/utils/response_codes.dart';
import 'package:telegraph/core/utils/formatters.dart';
import 'package:telegraph/core/utils/datetime_logic.dart';
import 'package:telegraph/features/meetings/services/meeting_database_service.dart';

class MeetingCommandHandler extends BaseCommandHandler {
  final MeetingDatabaseService dbService;
  MeetingCommandHandler(this.dbService, {super.clock});

  @override
  String get moduleKey => 'meeting';

  @override
  Future<String> handle(String input) async {
    final raw = input.toLowerCase().trim();
    if (raw.startsWith("$moduleKey start")) return await _handleStart(input);
    if (raw.startsWith("$moduleKey log")) return await _handleLog(input);
    if (raw == "$moduleKey stop") return await _handleStop();
    if (raw == "$moduleKey status") return await _handleStatus();
    if (raw.startsWith("$moduleKey list")) return await _handleList(input);
    if (raw.startsWith("$moduleKey delete")) {
      return performDelete(input, dbService.deleteMeeting);
    }
    return unknownSubCommand();
  }

  @override
  String get helpText =>
      "**Meetings:**\n- `meeting start [\"Note\"] @people #tags`\n- `meeting log [date] [range|duration] [\"Note\"] @people #tags`\n- `meeting stop` | `meeting list [date] [@person] [#tag]`";

  Future<String> _handleStart(String input) async {
    if (await dbService.getActiveMeeting() != null) {
      return ResponseFormatter.error(
        "Meeting already running.",
        errorCode: ErrorCode.alreadyActive,
      );
    }
    final cmd = ParsedCommand.parse(input, clock: clock);
    if (cmd.notes.isEmpty && cmd.participants.isEmpty && cmd.tags.isEmpty) {
      return ResponseFormatter.error(
        "Format: `meeting start [\"Note\"] @people #tags`",
        errorCode: ErrorCode.invalidFormat,
      );
    }
    await dbService.startMeeting(
      cmd.notes,
      cmd.tags,
      cmd.participants,
      startTime: clock(),
    );
    return ResponseFormatter.success(
      "Meeting Started",
      successCode: SuccessCode.meetingStarted,
      data: {
        "notes": cmd.notes.isEmpty ? "(no note)" : cmd.notes,
        "with": cmd.participants.map((p) => '@$p').toList(),
        "tags": cmd.tags.map((t) => '#$t').toList(),
        "at": Formatters.formatTime(clock()),
      },
    );
  }

  Future<String> _handleStop() async {
    final now = clock();
    final meeting = await dbService.stopActiveMeeting(stopTime: now);
    if (meeting == null) {
      return ResponseFormatter.error(
        "No active meeting.",
        errorCode: ErrorCode.noActiveSession,
      );
    }
    return ResponseFormatter.success(
      "Meeting Ended",
      successCode: SuccessCode.meetingStopped,
      data: {
        "notes": meeting.notes.isEmpty ? "(no note)" : meeting.notes,
        "duration": "${now.difference(meeting.startTime).inMinutes}m",
      },
    );
  }

  /// ✅ Fixed: Now handles tag and person filters
  Future<String> _handleList(String input) async {
    final cmd = ParsedCommand.parse(input, clock: clock);
    final date = cmd.date ?? clock();
    final tag = cmd.tags.isNotEmpty ? cmd.tags.first : null;
    final part = cmd.participants.isNotEmpty ? cmd.participants.first : null;

    final meetings = await dbService.getMeetings(
      date: date,
      tag: tag,
      participant: part,
    );
    if (meetings.isEmpty) {
      String msg = "📅 No meetings for ${Formatters.formatDate(date)}";
      if (tag != null) msg += " with tag #$tag";
      if (part != null) msg += " with @$part";
      return "$msg.";
    }
    final data = meetings
        .map(
          (m) => {
            "time":
                "${Formatters.formatShortTime(m.startTime)} - ${m.endTime != null ? Formatters.formatShortTime(m.endTime!) : '...'}",
            "notes": m.notes.isEmpty ? "(no note)" : m.notes,
            "people": m.displayParticipants,
            "tags": m.displayTags,
          },
        )
        .toList();
    return ResponseFormatter.format(
      "📅 **Meetings: ${Formatters.formatDate(date)}**",
      {"items": data},
    );
  }

  Future<String> _handleLog(String input) async {
    final cmd = ParsedCommand.parse(input, clock: clock);
    if (cmd.timeRange == null && cmd.duration == null) {
      return ResponseFormatter.error(
        "Format: `meeting log [date] [HH:mm-HH:mm|duration] [\"Note\"] @people #tags`",
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
    await dbService.recordCompletedMeeting(
      start: start,
      end: end,
      notes: cmd.notes,
      tags: cmd.tags,
      participants: cmd.participants,
    );
    return ResponseFormatter.success(
      "Meeting Logged",
      successCode: SuccessCode.meetingLogged,
      data: {
        "notes": cmd.notes.isEmpty ? "(no note)" : cmd.notes,
        "duration": Formatters.formatDuration(
          end.difference(start).inMinutes.toDouble(),
        ),
        "date": Formatters.formatDate(date),
        "tags": cmd.tags.map((t) => '#$t').toList(),
        "with": cmd.participants.map((p) => '@$p').toList(),
      },
    );
  }

  Future<String> _handleStatus() async {
    final active = await dbService.getActiveMeeting();
    if (active == null) return "📅 No active meetings.";
    return ResponseFormatter.format("🕒 **Active**", {
      "notes": active.notes.isEmpty ? "(no note)" : active.notes,
      "with": active.displayParticipants,
      "elapsed": "${clock().difference(active.startTime).inMinutes}m",
    });
  }
}
