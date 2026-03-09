enum ChatEntryType { user, ai, error, system, blank }

class ChatEntry {
  final String text;
  final String? reasoning;
  final ChatEntryType type;
  bool isReasoningExpanded;

  ChatEntry({
    required this.text,
    this.reasoning,
    required this.type,
    this.isReasoningExpanded = false,
  });

  void toggleReasoning() {
    isReasoningExpanded = !isReasoningExpanded;
  }
}
