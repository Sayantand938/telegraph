import 'base_module.dart';

class NoteModule extends BaseModule {
  NoteModule() : super('note');

  @override
  Future<String?> handle(Map<String, dynamic> data, DateTime timestamp) async {
    incrementCommand();
    final action = data['action'] as String?;
    final source = data['source'] ?? 'unknown';
    final title = data['title'] ?? 'Untitled Note';
    final content = data['content'] ?? '';
    final tags = _formatTags(data['tags']);

    if (action == 'list') {
      return '📝 **Notes List**\n• (No notes yet - implement storage)\n• Source: $source';
    }

    final preview = content.isNotEmpty
        ? (content.length > 60 ? content.substring(0, 60) + '...' : content)
        : '(empty)';

    return '📝 **Note Saved**\n• Title: $title\n• Tags: $tags\n• Preview: $preview\n• Source: $source';
  }

  String _formatTags(dynamic tags) {
    if (tags == null) return 'none';
    if (tags is List) return tags.isNotEmpty ? tags.join(', ') : 'none';
    return tags.toString();
  }
}
