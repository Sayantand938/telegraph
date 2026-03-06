import 'package:intl/intl.dart';

class DateParser {
  static DateTime? parseRelativeDate(String input, {DateTime? now}) {
    input = input.toLowerCase().trim();
    if (input.isEmpty) return null;
    final currentTime = now ?? DateTime.now();
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );

    if (input == 'today') return today;
    if (input == 'yesterday') return today.subtract(const Duration(days: 1));

    final daysAgoMatch = RegExp(r'^(\d+)\s+days?\s+ago$').firstMatch(input);
    if (daysAgoMatch != null) {
      final days = int.parse(daysAgoMatch.group(1)!);
      return today.subtract(Duration(days: days));
    }

    final weekdays = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };

    bool isLast = input.startsWith('last ');
    String weekdayQuery = isLast
        ? input.replaceFirst('last ', '').trim()
        : input;

    if (weekdays.containsKey(weekdayQuery)) {
      int targetWeekday = weekdays[weekdayQuery]!;
      int currentWeekday = today.weekday;

      int daysToSubtract = currentWeekday - targetWeekday;

      if (isLast) {
        // If it's currently Friday and I say "last Friday", I usually mean 7 days ago.
        // If it's Friday and I say "last Monday", I mean the Monday of this week.
        if (daysToSubtract <= 0) daysToSubtract += 7;
      } else {
        // Simple weekday (e.g., "monday") usually implies the most recent one
        if (daysToSubtract < 0) daysToSubtract += 7;
      }

      return today.subtract(Duration(days: daysToSubtract));
    }

    try {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(input)) {
        return DateFormat('yyyy-MM-dd').parseStrict(input);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
