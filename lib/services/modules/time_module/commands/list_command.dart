// lib/services/modules/time_module/commands/list_command.dart
import '../utils/time_utils.dart';
import '../../../database/database_helper.dart';

class ListCommand {
  final DatabaseHelper _db;
  ListCommand(this._db);

  Future<String> execute(Map<String, dynamic> data, DateTime timestamp) async {
    // 1. Extract filter parameters
    final dateFilter = data['date'] as String?; // Optional: "YYYY-MM-DD"
    final tagsFilter = parseTags(data['tags']); // Optional: list of tags
    final limit = data['limit'] as int? ?? 10; // Optional: max results

    // 2. Fetch all sessions
    final allSessions = await _db.querySessions();

    if (allSessions.isEmpty) {
      return '📋 **No Sessions**\n'
          '* No time sessions recorded yet.';
    }

    // 3. Apply filters
    final filteredSessions = allSessions
        .where((session) {
          // Date filter
          if (dateFilter != null && dateFilter.isNotEmpty) {
            final sessionStart = DateTime.parse(session['start_time']);
            final sessionDate =
                '${sessionStart.year}-${sessionStart.month.toString().padLeft(2, '0')}-${sessionStart.day.toString().padLeft(2, '0')}';
            if (sessionDate != dateFilter) {
              return false;
            }
          }

          // Tags filter (session must contain ALL specified tags)
          if (tagsFilter.isNotEmpty) {
            final sessionTags = parseTags(session['tags']);
            final hasAllTags = tagsFilter.every(
              (tag) => sessionTags.any(
                (sTag) => sTag.toLowerCase() == tag.toLowerCase(),
              ),
            );
            if (!hasAllTags) {
              return false;
            }
          }

          return true;
        })
        .take(limit)
        .toList();

    if (filteredSessions.isEmpty) {
      final filterInfo = <String>[];
      if (dateFilter != null && dateFilter.isNotEmpty) {
        filterInfo.add('date: `$dateFilter`');
      }
      if (tagsFilter.isNotEmpty) {
        filterInfo.add('tags: `${tagsFilter.join(", ")}`');
      }
      return '📋 **No Matching Sessions**\n'
          '* No sessions found with filters: ${filterInfo.join(", ")}\n'
          '* **Tip:** Use `@time --action list` without filters to see all sessions.';
    }

    // 4. Build response
    final buffer = StringBuffer();
    final hasFilters = dateFilter != null || tagsFilter.isNotEmpty;

    buffer.writeln(
      '📋 **Time Sessions** (${filteredSessions.length}${hasFilters ? ' filtered' : ''}${filteredSessions.length < allSessions.length ? ' of ${allSessions.length}' : ''})\n',
    );

    for (int i = 0; i < filteredSessions.length; i++) {
      final s = filteredSessions[i];
      final isActive = s['is_active'] == 1;
      final status = isActive ? '🟢 Active' : '⚪ Completed';
      final start = DateTime.parse(s['start_time']);
      final end = s['end_time'] != null
          ? DateTime.parse(s['end_time'])
          : DateTime.now();

      final diff = end.isAfter(start) ? end.difference(start) : Duration.zero;
      final duration = formatDuration(diff);
      final sessionTags = parseTags(s['tags']);
      final tagsDisplay = sessionTags.isNotEmpty
          ? sessionTags.map((t) => '#$t').join(' ')
          : '_no tags_';

      buffer.writeln('${i + 1}. **${s['note']}**');
      buffer.writeln('   * **ID:** `${s['id']}` | $status');
      buffer.writeln(
        '   * **Time:** ${formatDateTime(start)} — ${s['end_time'] != null ? formatDateTime(end) : "_Now_"}',
      );
      buffer.writeln('   * **Duration:** $duration');
      buffer.writeln('   * **Tags:** $tagsDisplay');
      buffer.writeln('');
    }

    buffer.writeln('---');
    if (hasFilters) {
      buffer.writeln('💡 *Clear filters:* `@time --action list`');
    }
    if (filteredSessions.length >= limit) {
      buffer.writeln('💡 *Show more:* `@time --action list --limit 20`');
    }

    return buffer.toString().trim();
  }
}
