// lib/services/modules/chat_module.dart
import 'base_module.dart';

class ChatModule extends BaseModule {
  ChatModule() : super('chat');

  @override
  Future<String?> handle(Map<String, dynamic> data, DateTime timestamp) async {
    incrementCommand();

    final action = data['action'] as String?;
    final response = data['response'] as String?;
    final error = data['error'] as String?;

    // 1. Prioritize Error Reporting
    if (error != null) {
      return '❌ **Error**\n'
          '$error';
    }

    // 2. Return the actual chat response if available
    if (response != null && response.trim().isNotEmpty) {
      return response.trim();
    }

    // 3. Fallback for debugging/internal actions
    return '💬 **Chat Response**\n'
        '• **Action:** ${action ?? 'unknown'}';
  }
}
