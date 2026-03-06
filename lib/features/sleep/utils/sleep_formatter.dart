import 'dart:convert';
import 'package:telegraph/features/sleep/models/sleep_session_model.dart';
import 'package:telegraph/core/utils/formatters.dart';

class SleepFormatter {
  static const _jsonEncoder = JsonEncoder.withIndent('  ');
  static const double _goalMinutes = 8 * 60;

  static String formatSessionListJson(
    DateTime date,
    List<SleepSessionModel> sessions,
  ) {
    final sessionData = sessions.map(_mapSessionToMap).toList();
    return _wrapWithMarkdown(
      "📅 **Sleep Sessions: ${Formatters.formatDate(date)}**",
      sessionData,
    );
  }

  static String formatDailySummaryJson({
    required DateTime date,
    required double totalMinutes,
    required int sessionCount,
    required double avgMinutes,
    required List<Map<String, dynamic>> tags,
  }) {
    final progress = (totalMinutes / _goalMinutes * 100).clamp(0.0, 100.0);

    final report = {
      "report": "Sleep Summary",
      "date": Formatters.formatDate(date),
      "stats": {
        "total_sleep": Formatters.formatDuration(totalMinutes),
        "goal_8h": "${progress.toStringAsFixed(1)}%",
        "sessions": sessionCount,
        "avg_sleep": Formatters.formatDuration(avgMinutes),
      },
      "tags": {
        for (var t in tags)
          "#${t['tag']}": Formatters.formatDuration(t['total_minutes']),
      },
    };

    return _wrapWithMarkdown("📊 **Sleep Report**", report);
  }

  static String formatStatsJson({
    required String period,
    required double avgSleepMinutes,
    required double bestSleepMinutes,
    required double worstSleepMinutes,
    required int totalSessions,
  }) {
    final report = {
      "report": "Sleep Statistics",
      "period": period,
      "stats": {
        "avg_sleep": Formatters.formatDuration(avgSleepMinutes),
        "best_sleep": Formatters.formatDuration(bestSleepMinutes),
        "worst_sleep": Formatters.formatDuration(worstSleepMinutes),
        "total_sessions": totalSessions,
      },
    };
    return _wrapWithMarkdown("📈 **Sleep Stats**", report);
  }

  static Map<String, dynamic> _mapSessionToMap(SleepSessionModel s) {
    final isRunning = s.endTime == null;
    final double durationMins = isRunning
        ? 0.0
        : s.endTime!.difference(s.startTime).inMinutes.toDouble();

    return {
      "id": s.id,
      "start": Formatters.formatShortTime(s.startTime),
      "end": isRunning ? "Running" : Formatters.formatShortTime(s.endTime!),
      "duration": isRunning
          ? "pending"
          : Formatters.formatDuration(durationMins),
      "notes": s.notes.isEmpty ? "(no note)" : s.notes,
      "tags": s.displayTags,
    };
  }

  static String _wrapWithMarkdown(String title, Object data) =>
      "$title\n```json\n${_jsonEncoder.convert(data)}\n```";
}
