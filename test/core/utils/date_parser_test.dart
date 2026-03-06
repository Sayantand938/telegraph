import 'package:flutter_test/flutter_test.dart';
import 'package:telegraph/core/utils/date_parser.dart';

void main() {
  group('DateParser', () {
    // We use a fixed Friday (March 6, 2026) as our "Now" reference
    final fridayMarch6 = DateTime(2026, 3, 6, 12, 0);

    test('should parse "today" correctly', () {
      final result = DateParser.parseRelativeDate('today', now: fridayMarch6);
      expect(result!.year, 2026);
      expect(result.month, 3);
      expect(result.day, 6);
    });

    test('should parse "yesterday" correctly', () {
      final result = DateParser.parseRelativeDate(
        'yesterday',
        now: fridayMarch6,
      );
      expect(result!.day, 5);
    });

    test('should parse "X days ago" correctly', () {
      final result = DateParser.parseRelativeDate(
        '3 days ago',
        now: fridayMarch6,
      );
      expect(result!.day, 3); // March 6 - 3 = March 3
    });

    test('should parse "last [weekday]" spanning back to previous week', () {
      // Current is Friday March 6. "last Monday" should be March 2.
      final monday = DateParser.parseRelativeDate(
        'last monday',
        now: fridayMarch6,
      );
      expect(monday!.day, 2);
      expect(monday.weekday, DateTime.monday);
    });

    test(
      'should parse "last friday" as exactly 7 days ago if today is friday',
      () {
        final lastFriday = DateParser.parseRelativeDate(
          'last friday',
          now: fridayMarch6,
        );
        // March 6 - 7 days = Feb 27
        expect(lastFriday!.month, 2);
        expect(lastFriday.day, 27);
      },
    );

    test('should handle case-insensitivity', () {
      final r1 = DateParser.parseRelativeDate('YESTERDAY', now: fridayMarch6);
      final r2 = DateParser.parseRelativeDate('Yesterday', now: fridayMarch6);
      expect(r1, r2);
    });

    test('should parse absolute ISO dates', () {
      final result = DateParser.parseRelativeDate('2026-01-01');
      expect(result!.year, 2026);
      expect(result.month, 1);
      expect(result.day, 1);
    });

    test('should return null for gibberish', () {
      final result = DateParser.parseRelativeDate('whenever');
      expect(result, isNull);
    });
  });
}
