import 'package:flutter/material.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // History of lines displayed in the terminal
  final List<String> _history = [
    'Flutter Terminal UI [Version 1.0.0]',
    'Type "help" to see available commands.',
    '',
  ];

  void _handleCommand(String input) {
    final command = input.trim().toLowerCase();
    if (command.isEmpty) return;

    setState(() {
      // Add the user's command to history
      _history.add('> $input');

      // Basic Command Logic
      switch (command) {
        case 'help':
          _history.add('Available commands:');
          _history.add('  help  - Show this message');
          _history.add('  clear - Clear the screen');
          _history.add('  echo  - Repeat text (e.g., echo hello)');
          _history.add('  date  - Show current date/time');
          _history.add('  exit  - "Close" terminal');
          break;
        case 'clear':
          _history.clear();
          break;
        case 'date':
          _history.add(DateTime.now().toString());
          break;
        case 'exit':
          _history.add('System: Exit command received. Goodbye.');
          break;
        default:
          if (command.startsWith('echo ')) {
            _history.add(input.substring(5));
          } else {
            _history.add('Error: Command "$command" not found.');
          }
      }
      _history.add(''); // Add a blank line for spacing
    });

    _controller.clear();
    _scrollToBottom();
    _focusNode.requestFocus(); // Keep the keyboard open
  }

  void _scrollToBottom() {
    // Small delay to ensure the frame is rendered before scrolling
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
  Widget build(BuildContext context) {
    return Scaffold(
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
                    final text = _history[index];
                    final isError = text.startsWith('Error:');
                    return Text(
                      text,
                      style: TextStyle(
                        color: isError ? Colors.red : Colors.white,
                        fontSize: 16,
                        fontFamily: 'JetBrainsMono',
                      ),
                    );
                  },
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
                        color: Colors.white,
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
}
