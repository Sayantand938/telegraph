import 'base_module.dart';

class TimeModule extends BaseModule {
  TimeModule() : super('time');

  @override
  String? handle(Map<String, dynamic> data, DateTime timestamp) {
    incrementCommand();

    final action = data['action'] as String?;
    final source = data['source'] ?? 'unknown';

    if (action == 'start') {
      final note = data['note'] ?? 'Untitled';
      final tags = _formatTags(data['tags']);
      return '⏱️ **Timer Started**\n• Note: $note\n• Tags: $tags\n• Time: ${_formatTime(timestamp)}\n• Source: $source';
    }
    if (action == 'stop') {
      return '⏹️ **Timer Stopped**\n• Duration: 00:00 (stub)\n• Source: $source';
    }
    if (action == 'status') {
      return '⏱️ **Timer Status**: ${data['running'] == true ? 'Running' : 'Idle'}\n• Source: $source';
    }

    return '❌ Unknown action: "$action". Try: start, stop, status\n• Source: $source';
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
