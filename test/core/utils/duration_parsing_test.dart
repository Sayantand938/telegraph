import 'package:flutter_test/flutter_test.dart';
import 'package:telegraph/core/utils/datetime_logic.dart';
import 'package:telegraph/core/utils/command_parser.dart';

void main() {
  group('Duration Parsing Logic', () {
    test('should parse various duration strings', () {
      expect(DateTimeLogic.parseDurationString("2h")?.inMinutes, 120);
      expect(DateTimeLogic.parseDurationString("45m")?.inMinutes, 45);
      expect(DateTimeLogic.parseDurationString("1h 30m")?.inMinutes, 90);
      expect(DateTimeLogic.parseDurationString("1.5h")?.inMinutes, 90);
      expect(DateTimeLogic.parseDurationString("0.5h")?.inMinutes, 30);
      expect(DateTimeLogic.parseDurationString("2h15m")?.inMinutes, 135);
      expect(DateTimeLogic.parseDurationString("2h 15m")?.inMinutes, 135);
    });

    test('should return null for non-duration strings', () {
      expect(DateTimeLogic.parseDurationString("lunch"), isNull);
      expect(DateTimeLogic.parseDurationString("10:00-11:00"), isNull);
    });

    test('ParsedCommand should detect duration in log command', () {
      final now = DateTime(2026, 3, 6, 12, 0);
      // This input generates args: ["2h", "15m"]
      final cmd = ParsedCommand.parse(
        'time log 2h 15m "Task"',
        clock: () => now,
      );

      expect(cmd.duration, isNotNull);
      expect(cmd.duration!.inMinutes, 135); // 120 + 15
      expect(cmd.notes, "Task");
    });

    test('ParsedCommand should detect duration with date', () {
      final now = DateTime(2026, 3, 6, 12, 0);
      final cmd = ParsedCommand.parse(
        'time log yesterday 1h "Old Task"',
        clock: () => now,
      );

      expect(cmd.date?.day, 5);
      expect(cmd.duration?.inHours, 1);
      expect(cmd.notes, "Old Task");
    });

    test('ParsedCommand should handle multi-word duration with date', () {
      final now = DateTime(2026, 3, 6, 12, 0);
      // Args: ["today", "1h", "20m"]
      final cmd = ParsedCommand.parse(
        'time log today 1h 20m "Combined"',
        clock: () => now,
      );

      expect(cmd.date?.day, 6);
      expect(cmd.duration?.inMinutes, 80);
    });
  });
}
