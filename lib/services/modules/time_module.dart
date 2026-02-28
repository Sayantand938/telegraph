import 'base_module.dart';

class TimeModule extends BaseModule {
  TimeModule() : super('time');

  @override
  String? handle(Map<String, dynamic> data, DateTime timestamp) {
    incrementCommand();

    // ✅ Explicit --action flag required
    final action = data['action'] as String?;

    if (action == 'start') {
      final note = data['note'] ?? 'Untitled';
      final tags = _formatTags(data['tags']);
      return '⏱️ **Timer Started**\n• Note: $note\n• Tags: $tags\n• Time: ${_formatTime(timestamp)}';
    }
    if (action == 'stop') {
      return '⏹️ **Timer Stopped**\n• Duration: 00:00 (stub)';
    }
    if (action == 'status') {
      return '⏱️ **Timer Status**: ${data['running'] == true ? 'Running' : 'Idle'}';
    }

    return '❌ Unknown action: "$action". Try: start, stop, status';
  }

  String _formatTags(dynamic tags) {
    if (tags == null) return 'none';
    if (tags is List) return tags.isNotEmpty ? tags.join(', ') : 'none';
    return tags.toString();
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
