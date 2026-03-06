// lib/core/utils/command_parser.dart
import 'package:telegraph/core/utils/date_parser.dart';
import 'package:telegraph/core/utils/datetime_logic.dart';

/// Represents a fully parsed command ready for business logic.
class ParsedCommand {
  final String raw;
  final String module;
  final String action;
  final String notes;
  final List<String> tags;
  final List<String> participants;
  final DateTime? date;
  final String? timeRange;
  final Duration? duration;
  final List<String> args;
  final Map<String, String> namedArgs;

  ParsedCommand({
    required this.raw,
    required this.module,
    required this.action,
    required this.notes,
    required this.tags,
    required this.participants,
    this.date,
    this.timeRange,
    this.duration,
    this.args = const [],
    this.namedArgs = const {},
  });

  static ParsedCommand parse(String input, {DateTime Function()? clock}) {
    try {
      final raw = input.trim();
      if (raw.isEmpty) {
        return ParsedCommand(
          raw: raw,
          module: '',
          action: '',
          notes: '',
          tags: [],
          participants: [],
        );
      }

      final lower = raw.toLowerCase();
      String module = '';
      String remainder = raw;

      if (lower.startsWith('time ')) {
        module = 'time';
        remainder = raw.substring(5);
      } else if (lower.startsWith('meeting ')) {
        module = 'meeting';
        remainder = raw.substring(8);
      } else if (lower.startsWith('task ')) {
        module = 'task';
        remainder = raw.substring(5);
      } else if (lower.startsWith('finance ')) {
        module = 'finance';
        remainder = raw.substring(8);
      } else if (lower.startsWith('sleep ')) {
        module = 'sleep';
        remainder = raw.substring(6);
      } else {
        return ParsedCommand(
          raw: raw,
          module: '',
          action: '',
          notes: '',
          tags: [],
          participants: [],
        );
      }

      String note = '';
      String noteFreeRemainder = remainder;

      final quoteMatch = RegExp(r'"([^"]*)"').firstMatch(remainder);
      if (quoteMatch != null) {
        note = quoteMatch.group(1)!.trim();
        noteFreeRemainder = remainder.replaceRange(
          quoteMatch.start,
          quoteMatch.end,
          ' ',
        );
      }

      final tags = _extractTags(noteFreeRemainder);
      final participants = _extractParticipants(noteFreeRemainder);

      // ✅ Updated: Cleaning regex to match the extraction regex
      String cleanRemainder = noteFreeRemainder
          .replaceAll(RegExp(r'#[^\s.,!?()]+'), ' ')
          .replaceAll(RegExp(r'@[^\s.,!?()]+'), ' ');

      final tokens = cleanRemainder
          .split(' ')
          .where((t) => t.isNotEmpty)
          .toList();

      final action = tokens.isNotEmpty ? tokens[0] : '';
      final rawArgs = tokens.length > 1 ? tokens.sublist(1) : <String>[];
      final args = _consolidateLastDayArgs(rawArgs);

      DateTime? parsedDate;
      String? parsedTimeRange;
      Duration? parsedDuration;

      if (action == 'list' || action == 'summary' || action == 'stats') {
        if (args.isNotEmpty) {
          parsedDate = DateParser.parseRelativeDate(
            args[0],
            now: clock?.call(),
          );
        }
      }

      if ((module == 'time' || module == 'meeting' || module == 'sleep') &&
          action == 'log') {
        if (args.isNotEmpty) {
          final dateTry = DateParser.parseRelativeDate(
            args[0],
            now: clock?.call(),
          );
          if (dateTry != null) {
            parsedDate = dateTry;
            if (args.length >= 2) {
              if (_validateTimeRange(args[1])) {
                parsedTimeRange = args[1];
              } else {
                parsedDuration = DateTimeLogic.parseDurationString(
                  args.sublist(1).join(' '),
                );
              }
            }
          } else {
            parsedDate = clock?.call();
            if (_validateTimeRange(args[0])) {
              parsedTimeRange = args[0];
            } else {
              parsedDuration = DateTimeLogic.parseDurationString(
                args.join(' '),
              );
            }
          }
        }
      } else if (module == 'task' && action == 'log') {
        if (args.isNotEmpty) {
          parsedDate =
              DateParser.parseRelativeDate(args[0], now: clock?.call()) ??
              clock?.call();
        }
      } else if (module == 'finance' && action == 'log') {
        if (args.length >= 2) {
          final dateTry = DateParser.parseRelativeDate(
            args[0],
            now: clock?.call(),
          );
          if (dateTry != null) {
            parsedDate = dateTry;
          } else if (args.length >= 3) {
            parsedDate = DateParser.parseRelativeDate(
              args[2],
              now: clock?.call(),
            );
          }
        }
      }

      return ParsedCommand(
        raw: raw,
        module: module,
        action: action,
        notes: note,
        tags: tags,
        participants: participants,
        date: parsedDate,
        timeRange: parsedTimeRange,
        duration: parsedDuration,
        args: args,
        namedArgs: {},
      );
    } catch (e) {
      return ParsedCommand(
        raw: input,
        module: '',
        action: '',
        notes: input,
        tags: [],
        participants: [],
      );
    }
  }

  static List<String> _consolidateLastDayArgs(List<String> args) {
    final consolidated = <String>[];
    for (int i = 0; i < args.length; i++) {
      if (args[i].toLowerCase() == 'last' && i + 1 < args.length) {
        consolidated.add('last ${args[i + 1]}');
        i++;
      } else {
        consolidated.add(args[i]);
      }
    }
    return consolidated;
  }

  static bool _validateTimeRange(String range) {
    return RegExp(r'^\d{1,2}:\d{2}-\d{1,2}:\d{2}$').hasMatch(range);
  }

  static List<String> _extractTags(String content) {
    // ✅ Fixed: Allow Emojis and special characters in tags, stop at whitespace or punctuation
    return RegExp(
      r'#([^\s.,!?()]+)',
    ).allMatches(content).map((m) => m.group(1)!.toLowerCase()).toList();
  }

  static List<String> _extractParticipants(String content) {
    return RegExp(
      r'@([^\s.,!?()]+)',
    ).allMatches(content).map((m) => m.group(1)!.toLowerCase()).toList();
  }

  static String getArgument(String input, String command) {
    final lowerInput = input.toLowerCase();
    final index = lowerInput.indexOf(command.toLowerCase());
    if (index == -1) return input.trim();
    return input.substring(index + command.length).trim();
  }
}
