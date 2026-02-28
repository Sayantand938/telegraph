import 'base_module.dart';

class NoteModule extends BaseModule {
  NoteModule() : super('note');

  @override
  String? handle(Map<String, dynamic> data, DateTime timestamp) {
    incrementCommand();

    // Notes don't require --action, but support it for future extensibility
    final action = data['action'] as String?;
    final title = data['title'] ?? 'Untitled Note';
    final content = data['content'] ?? '';
    final tags = _formatTags(data['tags']);

    if (action == 'list') {
      return '📝 **Notes List**\n• (No notes yet - implement storage)';
    }

    // Default: create/save note
    final preview = content.isNotEmpty
        ? (content.length > 60 ? content.substring(0, 60) + '...' : content)
        : '(empty)';

    return '📝 **Note Saved**\n• Title: $title\n• Tags: $tags\n• Preview: $preview';
  }

  String _formatTags(dynamic tags) {
    if (tags == null) return 'none';
    if (tags is List) return tags.isNotEmpty ? tags.join(', ') : 'none';
    return tags.toString();
  }
}
