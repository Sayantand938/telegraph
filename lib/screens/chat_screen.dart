import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/parser_manager.dart';
import 'package:flutter/foundation.dart';
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
    _parserManager.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _addBotMessage(
      '👋 Welcome to Telegraph!\n\n'
      'Try commands:\n'
      '• @time start --note "Work" --tags dev,flutter\n'
      '• @task add --title "Fix bug" --priority high\n'
      '• @note --title Ideas --content "Add export feature"\n\n'
      'Start with @ for manual mode, or type normally for AI mode.',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(Message(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final timestamp = DateTime.now();
    text.startsWith('@');

    setState(() {
      _messages.add(Message(text: text, isUser: true, timestamp: timestamp));
      _controller.clear();
      _isBotTyping = true;
    });
    _scrollToBottom();
    _focusNode.requestFocus();

    try {
      // Await parsed response from parser manager
      final response = await _parserManager.processMessage(text, timestamp);
      
      if (!mounted) return;
      
      setState(() {
        _messages.add(Message(text: response, isUser: false));
        _isBotTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(Message(text: '❌ Error: $e', isUser: false));
        _isBotTyping = false;
      });
      _scrollToBottom();
    }
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
      backgroundColor: Colors.grey[850],
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text('Profile', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.white),
              title: const Text('Notifications', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            Divider(color: Colors.grey[700]),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text('Parser Stats', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showParserStats();
              },
            ),
            if (kDebugMode) ...[
              Divider(color: Colors.grey[700]),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.grey),
                title: const Text('Local Mode Active', style: TextStyle(color: Colors.grey)),
                enabled: false,
              ),
            ],
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
              _buildStatRow('Manual Parser', stats['manualParser'] ?? 'Unknown'),
              _buildStatRow('Manual Trigger', stats['manualTrigger'] ?? '@'),
              const SizedBox(height: 12),
              const Text('Processed:', style: TextStyle(color: Colors.grey, fontSize: 12)),
              _buildStatRow('Total', '${stats['stats']?['totalProcessed'] ?? 0}'),
              _buildStatRow('AI Route', '${stats['stats']?['aiRouteCount'] ?? 0}'),
              _buildStatRow('Manual Route', '${stats['stats']?['manualRouteCount'] ?? 0}'),
              const SizedBox(height: 16),
              Text(
                '💡 Tip: Start with @ for Manual Parser',
                style: TextStyle(color: Colors.grey[400], fontSize: 12, fontFamily: 'JetBrains Mono'),
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
              itemBuilder: (context, index) => ChatBubble(message: _messages[index]),
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