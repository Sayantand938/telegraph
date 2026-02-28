// lib/services/modules/note_module.dart
import 'base_module.dart';

class NoteModule extends BaseModule {
  NoteModule() : super('note');

  @override
  Future<String?> handle(Map<String, dynamic> data, DateTime timestamp) async {
    incrementCommand();

    final action = data['action'] as String?;
    final title = data['title'] as String? ?? 'Untitled Note';
    final content = data['content'] as String? ?? '';
    final tags = _formatTags(data['tags']);

    // Handle 'list' action
    if (action == 'list') {
      return '📝 **Notes List**\n'
          '• (No notes yet - implement storage)';
    }

    // Generate preview for 'save' or default action
    final preview = content.isNotEmpty
        ? (content.length > 60 ? '${content.substring(0, 60)}...' : content)
        : '_(empty)_';

    return '📝 **Note Saved**\n'
        '• **Title:** $title\n'
        '• **Tags:** $tags\n'
        '• **Preview:** $preview';
  }

  String _formatTags(dynamic tags) {
    if (tags == null) return 'none';
    if (tags is List) return tags.isNotEmpty ? tags.join(', ') : 'none';
    if (tags is String) return tags.isNotEmpty ? tags : 'none';
    return tags.toString();
  }
}
