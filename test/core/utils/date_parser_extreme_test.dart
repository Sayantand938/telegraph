import 'package:flutter_test/flutter_test.dart';
import 'package:telegraph/core/utils/date_parser.dart';

void main() {
  group('DateParser Extreme Edge Cases', () {
    test('Leap Year: should handle Feb 29 correctly', () {
      // Reference date: March 1, 2024 (Day after Leap Day)
      final march1st = DateTime(2024, 3, 1, 12, 0);
      final result = DateParser.parseRelativeDate('yesterday', now: march1st);

      expect(result!.month, 2);
      expect(result.day, 29);
    });

    test('Massive relative offset', () {
      final now = DateTime(2026, 3, 7);
      final result = DateParser.parseRelativeDate('1000 days ago', now: now);

      // 1000 days before 2026-03-07 is 2023-06-11
      expect(result!.year, 2023);
      expect(result.month, 6);
      expect(result.day, 11);
    });

    test('Weekday case sensitivity and whitespace', () {
      final now = DateTime(2026, 3, 7); // Saturday
      final r1 = DateParser.parseRelativeDate('  mOnDaY  ', now: now);
      final r2 = DateParser.parseRelativeDate('monday', now: now);

      expect(r1, r2);
      expect(r1!.weekday, DateTime.monday);
    });

    test('Invalid ISO formats', () {
      expect(
        DateParser.parseRelativeDate('2026-13-01'),
        isNull,
      ); // Invalid month
      expect(DateParser.parseRelativeDate('2026-01-32'), isNull); // Invalid day
    });
  });
}
