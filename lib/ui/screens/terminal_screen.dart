import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';
import 'package:telegraph/models/chat_entry.dart';
import 'package:telegraph/services/ai/llm_service_new.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late final LlmServiceNew _llmService;

  // History of responses displayed in the terminal
  final List<ChatEntry> _history = [
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

  bool _isProcessing = false;

  Future<void> _handleCommand(String input) async {
    final command = input.trim().toLowerCase();
    if (command.isEmpty) return;

    setState(() {
      // Add the user's command to history
      _history.add(ChatEntry(text: '> $input', type: ChatEntryType.user));
      _isProcessing = true;
    });

    try {
      // Check if it's a built-in command
      final wasHandled = await _processCommand(command, input);

      // If not a built-in command, send to AI
      if (!wasHandled) {
        final aiResponse = await _llmService.sendMessage(input);
        final response = ChatEntry(
          text: aiResponse.content,
          reasoning: aiResponse.reasoning,
          type: ChatEntryType.ai,
        );

        setState(() {
          _history.add(response);
          if (response.text.isNotEmpty) {
            _history.add(ChatEntry(text: '', type: ChatEntryType.blank));
          }
          _isProcessing = false;
        });
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _history.add(ChatEntry(text: 'Error: $e', type: ChatEntryType.error));
        _history.add(ChatEntry(text: '', type: ChatEntryType.blank));
        _isProcessing = false;
      });
    }

    _controller.clear();
    _scrollToBottom();
    // Request focus after the frame is rendered to ensure it works
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  Future<bool> _processCommand(String command, String fullInput) async {
    switch (command) {
      case '/help':
        final response = ChatEntry(
          text: '''Available commands:
/help  - Show this message
/clear - Clear the screen
/health - Check if AI is online
/model - Show current model name
/echo  - Repeat text (e.g., /echo hello)
/date  - Show current date/time''',
          type: ChatEntryType.system,
        );
        setState(() {
          _history.add(response);
        });
        return true;
      case 'clear':
      case '/clear':
        setState(() {
          _history.clear();
        });
        return true;
      case '/date':
        final response = ChatEntry(
          text: DateTime.now().toString(),
          type: ChatEntryType.system,
        );
        setState(() {
          _history.add(response);
        });
        return true;
      case '/health':
        final isHealthy = await _llmService.healthCheck();
        final response = ChatEntry(
          text: isHealthy
              ? '✓ AI service is online and responding'
              : '✗ AI service is offline or unreachable',
          type: isHealthy ? ChatEntryType.system : ChatEntryType.error,
        );
        setState(() {
          _history.add(response);
        });
        return true;
      case '/model':
        final modelName = _llmService.getModelName();
        final response = ChatEntry(
          text: 'Current model: $modelName',
          type: ChatEntryType.system,
        );
        setState(() {
          _history.add(response);
        });
        return true;
      default:
        if (command.startsWith('/echo ')) {
          final response = ChatEntry(
            text: fullInput.substring(6),
            type: ChatEntryType.system,
          );
          setState(() {
            _history.add(response);
          });
          return true;
        }
        return false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _llmService = GetIt.instance<LlmServiceNew>();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _llmService.clearHistory();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Terminal History
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final entry = _history[index];
                    if (entry.type == ChatEntryType.blank) {
                      return const SizedBox(height: 8);
                    }

                    if (entry.reasoning != null) {
                      return _buildAiResponseWithReasoning(entry, index);
                    }

                    // Render markdown for AI responses
                    if (entry.type == ChatEntryType.ai) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: MarkdownBody(
                          data: entry.text,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 16,
                              fontFamily: 'JetBrainsMono',
                            ),
                            code: const TextStyle(
                              color: Colors.yellow,
                              fontSize: 14,
                              fontFamily: 'JetBrainsMono',
                              backgroundColor: Color(0xFF222222),
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            blockquote: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontFamily: 'JetBrainsMono',
                              fontStyle: FontStyle.italic,
                            ),
                            listBullet: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 16,
                              fontFamily: 'JetBrainsMono',
                            ),
                          ),
                        ),
                      );
                    }

                    return Text(
                      entry.text,
                      style: TextStyle(
                        color: _getTextColor(entry.type),
                        fontSize: 16,
                        fontFamily: 'JetBrainsMono',
                      ),
                    );
                  },
                ),
              ),

              // Loading indicator
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'AI is thinking...',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 14,
                      fontFamily: 'JetBrainsMono',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              // Input Area
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white, width: 2.0),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      '> ',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        cursorColor: Colors.greenAccent,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'JetBrainsMono',
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onSubmitted: _handleCommand,
                        enabled: !_isProcessing,
                      ),
                    ),
                    if (_isProcessing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.greenAccent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiResponseWithReasoning(ChatEntry entry, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collapsible reasoning section
        _buildCollapsibleReasoning(entry, index),
        const SizedBox(height: 8),
        // AI response content with markdown
        Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: MarkdownBody(
            data: entry.text,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 16,
                fontFamily: 'JetBrainsMono',
              ),
              code: const TextStyle(
                color: Colors.yellow,
                fontSize: 14,
                fontFamily: 'JetBrainsMono',
                backgroundColor: Color(0xFF222222),
              ),
              codeblockDecoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(4),
              ),
              blockquote: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontFamily: 'JetBrainsMono',
                fontStyle: FontStyle.italic,
              ),
              listBullet: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 16,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsibleReasoning(ChatEntry entry, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _history[index] = _history[index].copyWith(
                  isReasoningExpanded: !_history[index].isReasoningExpanded,
                );
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    entry.isReasoningExpanded
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: Colors.yellow,
                    size: 20,
                  ),
                  const Text(
                    'Thinking',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 14,
                      fontFamily: 'JetBrainsMono',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Reasoning content with markdown
          if (entry.isReasoningExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: MarkdownBody(
                data: entry.reasoning!,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily: 'JetBrainsMono',
                    fontStyle: FontStyle.italic,
                  ),
                  code: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 12,
                    fontFamily: 'JetBrainsMono',
                    backgroundColor: Color(0xFF222222),
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getTextColor(ChatEntryType type) {
    switch (type) {
      case ChatEntryType.user:
        return Colors.greenAccent;
      case ChatEntryType.ai:
        return Colors.cyanAccent;
      case ChatEntryType.error:
        return Colors.red;
      case ChatEntryType.system:
        return Colors.grey;
      case ChatEntryType.blank:
        return Colors.transparent;
    }
  }
}
