import 'package:flutter_test/flutter_test.dart';
import 'package:telegraph/core/utils/datetime_logic.dart';

void main() {
  group('DateTimeLogic Rollover Edge Cases', () {
    test('New Year Rollover: should split correctly from Dec 31 to Jan 1', () {
      final start = DateTime(2025, 12, 31, 22, 0); // New Year's Eve 10PM
      final end = DateTime(2026, 1, 1, 2, 0); // New Year's Day 2AM

      final segments = DateTimeLogic.splitAcrossDays(start, end);

      expect(segments.length, 2);
      expect(segments[0].start.year, 2025);
      expect(segments[1].start.year, 2026);
      expect(segments[1].start.month, 1);
      expect(segments[1].start.day, 1);
    });

    test('Month End: should handle Feb 28 to March 1 (Non-Leap)', () {
      final start = DateTime(2025, 2, 28, 23, 0);
      final end = DateTime(2025, 3, 1, 1, 0);

      final segments = DateTimeLogic.splitAcrossDays(start, end);
      expect(segments.length, 2);
      expect(segments[1].start.month, 3);
      expect(segments[1].start.day, 1);
    });

    test('Duration Parsing: Fractional hours with decimals', () {
      // 0.5h = 30m, 1.25h = 75m
      expect(DateTimeLogic.parseDurationString('0.5h')?.inMinutes, 30);
      expect(DateTimeLogic.parseDurationString('1.25h')?.inMinutes, 75);
    });
  });
}
