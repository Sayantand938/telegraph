import 'base_module.dart';

/// Module for general AI conversations (fallback module)
class ChatModule extends BaseModule {
  ChatModule() : super('chat');

  @override
  String? handle(Map<String, dynamic> data, DateTime timestamp) {
    incrementCommand();

    final action = data['action'] as String?;
    final source = data['source'] ?? 'unknown';
    final response = data['response'] as String?;
    final error = data['error'] as String?;

    if (error != null) {
      return '❌ **Error**\n$error\n• Source: $source';
    }

    if (response != null && response.isNotEmpty) {
      return response;
    }

    return '💬 **Chat Response**\n• Action: $action\n• Source: $source';
  }
}
