import 'base_parser.dart';

/// Parser for AI-processed messages (default route)
class AIParser extends BaseParser {
  AIParser() : super('AI Parser');

  @override
  Future<String> parse(String message, DateTime timestamp) async {
    // TODO: Add actual AI parsing logic here
    // For now, return a clean confirmation
    
    if (message.toLowerCase().contains('help')) {
      return '🤖 **AI Mode Help**\n\n'
          'I can assist with:\n'
          '• 🕐 Time tracking: `@time start --note "Work"`\n'
          '• ✅ Task management: `@task add --title "Fix bug"`\n'
          '• 📝 Notes: `@note --title Ideas --content "New feature"`\n\n'
          'Start with `@` for manual parsing, or type naturally for AI mode.';
    }

    return '🤖 **AI Mode Received**\n\n'
        'Message: "$message"\n\n'
        '✨ *LLM integration pending - try `@` commands for instant parsed output*';
  }
}