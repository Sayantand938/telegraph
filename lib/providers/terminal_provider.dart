import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telegraph/models/chat_entry.dart';
import 'package:telegraph/services/ai/llm_service_new.dart';
import 'package:telegraph/core/errors/exceptions.dart';
import 'package:logger/logger.dart';

// Riverpod v3 provider using Notifier (no code generation required)

class TerminalNotifier extends Notifier<List<ChatEntry>> {
  final Logger _logger = Logger();

  @override
  List<ChatEntry> build() => _initialState;

  static List<ChatEntry> get _initialState => [
    ChatEntry(
      text: 'Flutter Terminal AI [Version 1.0.0]',
      type: ChatEntryType.system,
    ),
    ChatEntry(
      text: 'Type "help" to see available commands.',
      type: ChatEntryType.system,
    ),
    ChatEntry(
      text: 'Chat with AI by typing any message.',
      type: ChatEntryType.system,
    ),
    ChatEntry(text: '', type: ChatEntryType.blank),
  ];

  Future<void> handleCommand(String input, LlmServiceNew llmService) async {
    final command = input.trim().toLowerCase();
    if (command.isEmpty) return;

    _logger.i('Handling command: $input');

    // Add user message
    state = [...state, ChatEntry(text: '> $input', type: ChatEntryType.user)];

    try {
      final wasHandled = _processCommand(command, input, llmService);
      if (!wasHandled) {
        _logger.d('Sending to AI service...');
        final response = await llmService.sendMessage(input);
        _logger.d('Received response from AI service');
        state = [
          ...state,
          ChatEntry(
            text: response.content,
            reasoning: response.reasoning,
            type: ChatEntryType.ai,
          ),
        ];
        if (response.content.isNotEmpty) {
          state = [...state, ChatEntry(text: '', type: ChatEntryType.blank)];
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error in handleCommand', error: e, stackTrace: stackTrace);
      final errorMsg = e is AppException
          ? _formatException(e)
          : 'Unexpected error: $e';
      state = [...state, ChatEntry(text: errorMsg, type: ChatEntryType.error)];
      state = [...state, ChatEntry(text: '', type: ChatEntryType.blank)];
    }
  }

  bool _processCommand(
    String command,
    String fullInput,
    LlmServiceNew llmService,
  ) {
    switch (command) {
      case '/help':
        _addSystemEntry('''Available commands:
/help  - Show this message
/clear - Clear the screen
/health - Check if AI is online
/model - Show current model name
/echo  - Repeat text (e.g., /echo hello)
/date  - Show current date/time''');
        return true;

      case 'clear':
      case '/clear':
        clear();
        return true;

      case '/date':
        _addSystemEntry(DateTime.now().toString());
        return true;

      case '/health':
      case '/model':
        // These require async operations - mark as handled to avoid sending to AI
        return true;

      default:
        if (command.startsWith('/echo ')) {
          _addSystemEntry(fullInput.substring(6));
          return true;
        }
        return false;
    }
  }

  void _addSystemEntry(String text) {
    state = [...state, ChatEntry(text: text, type: ChatEntryType.system)];
  }

  void clear() {
    state = [
      ChatEntry(text: 'Screen cleared', type: ChatEntryType.system),
      ChatEntry(text: '', type: ChatEntryType.blank),
    ];
  }

  String _formatException(AppException e) {
    if (e is ValidationException) {
      return 'Validation error: ${e.message}';
    } else if (e is DatabaseException) {
      return 'Database error: ${e.message}';
    } else if (e is AiServiceException) {
      return 'AI service error: ${e.message}';
    } else if (e is ToolException) {
      return 'Tool error (${e.toolName}): ${e.message}';
    } else if (e is NotFoundException) {
      return 'Not found: ${e.message}';
    } else if (e is BusinessLogicException) {
      return 'Cannot complete: ${e.message}';
    } else {
      return 'Error: ${e.message}';
    }
  }
}

// Provider declaration
final terminalProvider = NotifierProvider<TerminalNotifier, List<ChatEntry>>(
  TerminalNotifier.new,
);
