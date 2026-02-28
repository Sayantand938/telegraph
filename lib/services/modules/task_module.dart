import 'base_module.dart';

class TaskModule extends BaseModule {
  TaskModule() : super('task');

  @override
  String? handle(Map<String, dynamic> data, DateTime timestamp) {
    incrementCommand();

    final action = data['action'] as String?;

    if (action == 'add') {
      final title = data['title'] ?? 'Untitled Task';
      final priority = data['priority'] ?? 'medium';
      final tags = _formatTags(data['tags']);
      return '📋 **Task Created**\n• Title: $title\n• Priority: $priority\n• Tags: $tags';
    }
    if (action == 'list') {
      return '📋 **Task List**\n• (No tasks yet - implement storage)';
    }
    if (action == 'complete') {
      final id = data['id'] ?? 'unknown';
      return '✅ **Task Completed**: #$id';
    }

    return '❌ Unknown action: "$action". Try: add, list, complete';
  }

  String _formatTags(dynamic tags) {
    if (tags == null) return 'none';
    if (tags is List) return tags.isNotEmpty ? tags.join(', ') : 'none';
    return tags.toString();
  }
}
