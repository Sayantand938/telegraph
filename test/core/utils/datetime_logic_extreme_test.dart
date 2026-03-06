import 'package:flutter_test/flutter_test.dart';
import 'package:telegraph/core/utils/datetime_logic.dart';

void main() {
  group('DateTimeLogic Paradoxes', () {
    final baseDate = DateTime(2026, 3, 7);

    test('Illegal Time: should return null for impossible hours/minutes', () {
      expect(DateTimeLogic.parseTimeString(baseDate, '25:00'), isNull);
      expect(DateTimeLogic.parseTimeString(baseDate, '12:61'), isNull);
      expect(DateTimeLogic.parseTimeString(baseDate, '-1:30'), isNull);
      expect(DateTimeLogic.parseTimeString(baseDate, 'noon'), isNull);
    });

    test(
      'Backward Range: 10:00-09:00 should assume next day (23 hour session)',
      () {
        final range = DateTimeLogic.parseCompactRange(baseDate, '10:00-09:00');
        final start = range!.keys.first;
        final end = range.values.first;

        expect(end.isAfter(start), isTrue);
        expect(end.difference(start).inHours, 23);
      },
    );

    test(
      'Zero Duration Split: should handle start and end being identical',
      () {
        final start = DateTime(2026, 3, 7, 10, 0);
        final segments = DateTimeLogic.splitAcrossDays(start, start);
        // Logic currently returns [] if !start.isBefore(end)
        expect(segments, isEmpty);
      },
    );

    test('Duration Parsing: should ignore extra spaces and junk', () {
      expect(DateTimeLogic.parseDurationString('  1h    30m  ')?.inMinutes, 90);
      expect(
        DateTimeLogic.parseDurationString('just 45m please')?.inMinutes,
        45,
      );
    });
  });
}
