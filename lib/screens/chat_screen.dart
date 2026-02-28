import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/parser_manager.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ParserManager _parserManager = ParserManager();

  final List<Message> _messages = [];
  bool _isBotTyping = false;

  @override
  void initState() {
    super.initState();
    // Initialize the parser manager with AI and Manual sub-modules
    _parserManager.init();

    // Request focus when widget loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final timestamp = DateTime.now();

    // Send to ParserManager for routing (AI or Manual based on @ prefix)
    _parserManager.processMessage(text, timestamp);

    setState(() {
      _messages.add(Message(text: text, isUser: true, timestamp: timestamp));
      _controller.clear();
      _isBotTyping = true;
    });

    _scrollToBottom();
    _focusNode.requestFocus();

    // Echo response after delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _messages.add(Message(text: text, isUser: false));
        _isBotTyping = false;
      });
      _scrollToBottom();
      _focusNode.requestFocus();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.grey[850], // ← Remove 'const' from Container below
      builder: (context) => Container(
        // ← Was: 'const Container' - REMOVE const
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text(
                'Profile',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.white),
              title: const Text(
                'Notifications',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text(
                'Settings',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context),
            ),
            Divider(color: Colors.grey[700]),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text(
                'Parser Stats',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showParserStats();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showParserStats() {
    final stats = _parserManager.getStats();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Parser Manager Stats',
          style: TextStyle(color: Colors.white, fontFamily: 'JetBrains Mono'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('AI Parser', stats['aiParser'] ?? 'Unknown'),
              _buildStatRow(
                'Manual Parser',
                stats['manualParser'] ?? 'Unknown',
              ),
              _buildStatRow('Manual Trigger', stats['manualTrigger'] ?? '@'),
              _buildStatRow('Last Updated', stats['timestamp'] ?? 'N/A'),
              const SizedBox(height: 16),
              Text(
                '💡 Tip: Start a message with @ to route to Manual Parser',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Echo Bot',
        isTyping: _isBotTyping,
        onMenuPressed: _showMenu,
      ),
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          if (_isBotTyping) const TypingIndicator(),
          Divider(color: Colors.grey[800], height: 1),
          ChatInput(
            controller: _controller,
            focusNode: _focusNode,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
