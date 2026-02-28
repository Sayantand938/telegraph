// lib/services/modules/task_module.dart
import 'base_module.dart';

class TaskModule extends BaseModule {
  TaskModule() : super('task');

  @override
  Future<String?> handle(Map<String, dynamic> data, DateTime timestamp) async {
    incrementCommand();
    final action = data['action'] as String?;

    switch (action) {
      case 'add':
        final title = data['title'] as String? ?? 'Untitled Task';
        final priority = data['priority'] as String? ?? 'medium';
        final tags = _formatTags(data['tags']);

        return '📋 **Task Created**\n'
            '• **Title:** $title\n'
            '• **Priority:** $priority\n'
            '• **Tags:** $tags';

      case 'list':
        return '📋 **Task List**\n'
            '• (No tasks yet - implement storage)';

      case 'complete':
        final id = data['id'] ?? 'unknown';
        return '✅ **Task Completed**: #$id';

      default:
        return '❌ **Unknown Action**: "$action"\n'
            '* **Try:** `add`, `list`, `complete`';
    }
  }

  String _formatTags(dynamic tags) {
    if (tags == null) return 'none';
    if (tags is List) return tags.isNotEmpty ? tags.join(', ') : 'none';
    if (tags is String) return tags.isNotEmpty ? tags : 'none';
    return tags.toString();
  }
}
