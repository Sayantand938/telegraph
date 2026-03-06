import 'dart:convert';
import 'package:telegraph/features/time/models/session_model.dart';
import 'package:telegraph/core/utils/formatters.dart';

class TimeFormatter {
  static const _jsonEncoder = JsonEncoder.withIndent('  ');
  static const double _dailyGoalMinutes = 8 * 60;

  static String formatSessionListJson(
    DateTime date,
    List<SessionModel> sessions,
  ) {
    final sessionData = sessions.map(_mapSessionToMap).toList();
    return _wrapWithMarkdown(
      "📅 **List Sessions: ${Formatters.formatDate(date)}**",
      sessionData,
    );
  }

  static String formatDailySummaryJson({
    required DateTime date,
    required double totalMinutes,
    required int sessionCount,
    required List<Map<String, dynamic>> tags,
    required List<Map<String, dynamic>> hourlyData,
  }) {
    final progress = (totalMinutes / _dailyGoalMinutes * 100).clamp(0.0, 100.0);
    final report = {
      "report": "Summary",
      "date": Formatters.formatDate(date),
      "stats": {
        "total_time": Formatters.formatDuration(totalMinutes),
        "goal_8h": "${progress.toStringAsFixed(1)}%",
        "sessions": sessionCount,
        "avg_session": sessionCount > 0
            ? Formatters.formatDuration(totalMinutes / sessionCount)
            : "0m",
      },
      "shifts": _calculateShiftData(hourlyData),
      "tags": {
        for (var t in tags)
          "#${t['tag']}": Formatters.formatDuration(t['total_minutes']),
      },
    };
    return _wrapWithMarkdown("📊 **Summary Report**", report);
  }

  static String formatHourlyStatsJson(
    DateTime? date,
    List<Map<String, dynamic>> data,
  ) {
    final report = {
      "report": "Hourly Stats",
      "period": date != null ? Formatters.formatDate(date) : "All Time",
      "distribution": {
        for (var e in data)
          "${e['hour'].toString().padLeft(2, '0')}:00":
              "${(e['total_minutes'] as double).round()}m",
      },
    };
    return _wrapWithMarkdown("🕒 **Hourly Statistics**", report);
  }

  static Map<String, dynamic> _mapSessionToMap(SessionModel s) {
    final isRunning = s.endTime == null;
    return {
      "id": s.id,
      "start": Formatters.formatShortTime(s.startTime),
      "end": isRunning ? "Running" : Formatters.formatShortTime(s.endTime!),
      "duration": isRunning
          ? "pending"
          : "${s.endTime!.difference(s.startTime).inMinutes}m",
      "notes": s.notes,
      "tags": s.displayTags,
    };
  }

  static Map<String, String> _calculateShiftData(
    List<Map<String, dynamic>> hourlyData,
  ) {
    List<double> shiftMins = List.filled(6, 0.0);
    for (var h in hourlyData) {
      int hour = h['hour'] as int;
      if (hour >= 0 && hour < 24) {
        shiftMins[hour ~/ 4] += (h['total_minutes'] as num).toDouble();
      }
    }
    return {
      "S1 (00-04)": Formatters.formatDuration(shiftMins[0]),
      "S2 (04-08)": Formatters.formatDuration(shiftMins[1]),
      "S3 (08-12)": Formatters.formatDuration(shiftMins[2]),
      "S4 (12-16)": Formatters.formatDuration(shiftMins[3]),
      "S5 (16-20)": Formatters.formatDuration(shiftMins[4]),
      "S6 (20-24)": Formatters.formatDuration(shiftMins[5]),
    };
  }

  static String _wrapWithMarkdown(String title, Object data) =>
      "$title\n```json\n${_jsonEncoder.convert(data)}\n```";
}
