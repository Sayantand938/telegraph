import 'package:flutter_test/flutter_test.dart';
import 'package:telegraph/core/utils/datetime_logic.dart';

void main() {
  group('DateTimeLogic', () {
    test('isSameDay should detect same calendar days', () {
      final d1 = DateTime(2026, 3, 6, 10, 0);
      final d2 = DateTime(2026, 3, 6, 23, 59);
      final d3 = DateTime(2026, 3, 7, 0, 1);

      expect(DateTimeLogic.isSameDay(d1, d2), isTrue);
      expect(DateTimeLogic.isSameDay(d1, d3), isFalse);
    });

    test('parseCompactRange should handle same-day range', () {
      final date = DateTime(2026, 3, 6);
      final result = DateTimeLogic.parseCompactRange(date, "10:00-12:30");

      expect(result, isNotNull);
      expect(result!.keys.first, DateTime(2026, 3, 6, 10, 0));
      expect(result.values.first, DateTime(2026, 3, 6, 12, 30));
    });

    test('parseCompactRange should handle midnight crossover', () {
      final date = DateTime(2026, 3, 6);
      // Starts 11 PM, Ends 1 AM next day
      final result = DateTimeLogic.parseCompactRange(date, "23:00-01:00");

      expect(result, isNotNull);
      expect(result!.keys.first, DateTime(2026, 3, 6, 23, 0));
      expect(result.values.first, DateTime(2026, 3, 7, 1, 0));
    });

    test('splitAcrossDays should split a 3-day session correctly', () {
      final start = DateTime(2026, 3, 6, 22, 0); // Friday 10PM
      final end = DateTime(2026, 3, 8, 02, 0); // Sunday 2AM

      final segments = DateTimeLogic.splitAcrossDays(start, end);

      // Should be 3 segments:
      // 1. Mar 6 (22:00 to 23:59)
      // 2. Mar 7 (00:00 to 23:59)
      // 3. Mar 8 (00:00 to 02:00)
      expect(segments.length, 3);
      expect(segments[0].start.day, 6);
      expect(segments[1].start.day, 7);
      expect(segments[2].start.day, 8);
      expect(segments[2].end.hour, 2);
    });
  });
}
