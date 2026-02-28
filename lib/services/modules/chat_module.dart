import 'base_module.dart';

class ChatModule extends BaseModule {
  ChatModule() : super('chat');

  @override
  Future<String?> handle(Map<String, dynamic> data, DateTime timestamp) async {
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
