import 'llm_client.dart';

/// Manages conversation history and context
class ConversationManager {
  final List<LlmMessage> _history = [];
  final int maxHistoryLength;

  ConversationManager({this.maxHistoryLength = 50});

  /// Get a copy of the current conversation history
  List<LlmMessage> getHistory() {
    return List.unmodifiable(_history);
  }

  /// Add a user message to history
  void addUserMessage(String content) {
    _history.add(LlmMessage.user(content));
    _trimIfNeeded();
  }

  /// Add an assistant message to history
  void addAssistantMessage(
    String content, {
    String? reasoning,
    List<LlmToolCall>? toolCalls,
  }) {
    _history.add(
      LlmMessage.assistant(content, reasoning: reasoning, toolCalls: toolCalls),
    );
    _trimIfNeeded();
  }

  /// Add a tool response message to history
  void addToolMessage(String content) {
    _history.add(LlmMessage.tool(content));
    _trimIfNeeded();
  }

  /// Add multiple tool responses to history
  void addToolResponses(List<String> responses) {
    for (final response in responses) {
      _history.add(LlmMessage.tool(response));
    }
    _trimIfNeeded();
  }

  /// Clear all conversation history
  void clear() {
    _history.clear();
  }

  /// Get the most recent user message (for initial request when history is empty)
  String? getLastUserMessage() {
    for (final msg in _history.reversed) {
      if (msg.role == 'user') {
        return msg.content;
      }
    }
    return null;
  }

  /// Prepare the conversation context for an LLM request
  /// This includes the full history up to the max length
  List<LlmMessage> prepareContext() {
    if (_history.isEmpty) {
      return [];
    }

    // Return a copy to prevent external modification
    return List.from(_history);
  }

  /// Remove the oldest messages if history exceeds max length
  void _trimIfNeeded() {
    while (_history.length > maxHistoryLength) {
      // Remove oldest messages (from the beginning)
      // Keep system messages if any, but for now we just trim
      _history.removeAt(0);
    }
  }

  /// Get history size
  int get length => _history.length;

  /// Check if there is any conversation history
  bool get hasHistory => _history.isNotEmpty;

  /// Get the last N messages
  List<LlmMessage> getLastMessages(int n) {
    final start = _history.length - n;
    if (start < 0) {
      return List.from(_history);
    }
    return _history.sublist(start);
  }

  /// Remove the last message (useful for rollback scenarios)
  void removeLastMessage() {
    if (_history.isNotEmpty) {
      _history.removeLast();
    }
  }

  /// Replace the last assistant message (for updating with tool call results)
  void replaceLastAssistantMessage(String content, {String? reasoning}) {
    if (_history.isNotEmpty && _history.last.role == 'assistant') {
      _history[_history.length - 1] = LlmMessage.assistant(
        content,
        reasoning: reasoning,
        toolCalls: _history.last.toolCalls,
      );
    }
  }
}
