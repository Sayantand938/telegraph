// lib/core/utils/datetime_logic.dart
class DateTimeLogic {
  /// Represents a time segment with start and end boundaries.
  static List<TimeSegment> splitAcrossDays(DateTime start, DateTime end) {
    try {
      if (!start.isBefore(end)) return [];
      final segments = <TimeSegment>[];
      var currentStart = start;
      while (!isSameDay(currentStart, end)) {
        // End of the current day: 23:59:59.000 (standardized)
        final endOfCurrentDay = DateTime(
          currentStart.year,
          currentStart.month,
          currentStart.day,
          23,
          59,
          59,
        );
        segments.add(TimeSegment(start: currentStart, end: endOfCurrentDay));
        // Start of the next day: 00:00:00.000
        currentStart = DateTime(
          currentStart.year,
          currentStart.month,
          currentStart.day + 1,
        );
      }
      // Add the final segment (the portion on the last day)
      segments.add(TimeSegment(start: currentStart, end: end));
      return segments;
    } catch (e) {
      return [];
    }
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime? parseTimeString(DateTime date, String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length < 2) return null;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  static Map<DateTime, DateTime>? parseCompactRange(
    DateTime date,
    String rangeStr,
  ) {
    try {
      if (!rangeStr.contains('-')) return null;
      final parts = rangeStr.split('-');
      if (parts.length != 2) return null;

      final start = parseTimeString(date, parts[0]);
      var end = parseTimeString(date, parts[1]);

      if (start == null || end == null) return null;

      if (end.isBefore(start)) {
        end = end.add(const Duration(days: 1));
      }
      return {start: end};
    } catch (_) {
      return null;
    }
  }

  /// ✅ New: Parses strings like "2h 30m", "1.5h", "45m" into a Duration.
  static Duration? parseDurationString(String input) {
    input = input.toLowerCase().trim();
    if (input.isEmpty) return null;

    int totalMinutes = 0;
    bool matched = false;

    // Pattern for "1.5h" or "2h"
    final hourMatch = RegExp(r'(\d+(\.\d+)?)h').firstMatch(input);
    if (hourMatch != null) {
      final hours = double.tryParse(hourMatch.group(1)!) ?? 0;
      totalMinutes += (hours * 60).round();
      matched = true;
    }

    // Pattern for "30m"
    final minuteMatch = RegExp(r'(\d+)m').firstMatch(input);
    if (minuteMatch != null) {
      final minutes = int.tryParse(minuteMatch.group(1)!) ?? 0;
      totalMinutes += minutes;
      matched = true;
    }

    if (!matched) return null;
    return Duration(minutes: totalMinutes);
  }

  static bool crossesMidnight(DateTime start, DateTime end) {
    return !isSameDay(start, end);
  }
}

class TimeSegment {
  final DateTime start;
  final DateTime end;
  TimeSegment({required this.start, required this.end});
}
