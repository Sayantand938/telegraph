import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telegraph/core/engine/telegraph_engine.dart';
import 'package:telegraph/core/utils/logger.dart';
import 'package:telegraph/features/chat/models/message_model.dart';

class ChatController extends ChangeNotifier {
  final TelegraphEngine _engine;

  // Configuration
  static const String _workerUrl =
      "https://telegraph-ai-worker.sayantand938.workers.dev/v1/chat/completions";
  static const String _aiPrefsKey = 'ai_analysis_enabled';

  // State
  final List<MessageModel> _messages = [];
  bool _isTyping = false;
  bool _isReady = false;
  bool _isAiEnabled = false;
  String? _statusMessage;
  String? _initError;

  // Getters
  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get isReady => _isReady;
  bool get isAiEnabled => _isAiEnabled;
  String? get statusMessage => _statusMessage;
  String? get initError => _initError;

  ChatController({required TelegraphEngine engine}) : _engine = engine;

  /// Toggle AI Analysis and persist setting to disk
  Future<void> toggleAi(bool value) async {
    _isAiEnabled = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_aiPrefsKey, value);
      Logger.log("Alison AI Mode saved: ${value ? 'ACTIVE' : 'INACTIVE'}");
    } catch (e) {
      Logger.error("Failed to save AI setting", err: e);
    }
  }

  Future<void> initialize() async {
    try {
      // 1. Load Persistence Settings
      final prefs = await SharedPreferences.getInstance();
      _isAiEnabled = prefs.getBool(_aiPrefsKey) ?? false;

      // 2. Load Chat History
      final history = await _engine.loadChatHistory();
      _messages.addAll(history);

      if (_messages.isEmpty) {
        _messages.add(
          MessageModel(
            text:
                """👋 **Hi, I'm Alison!**
I'm ready to track your day, Boss.
**Active Modules:** ${_engine.registeredModuleCount}
Type **help** to see all commands.""",
            isMe: false,
          ),
        );
      }

      _isReady = true;
      _initError = null;
      _statusMessage = 'online';
      Logger.init('ChatController initialized successfully');
    } catch (e, stackTrace) {
      Logger.error(
        'Init failed',
        tag: 'ChatController',
        err: e,
        stack: stackTrace,
      );
      _isReady = true;
      _initError = '⚠️ Degraded mode';
      _messages.add(
        MessageModel(
          text: '⚠️ System alert: Initialization issues.',
          isMe: false,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> sendMessage(String userText) async {
    if (!_isReady || userText.trim().isEmpty) return;

    final userMessage = MessageModel(text: userText, isMe: true);
    _addUserMessage(userMessage);
    await _engine.saveMessageToHistory(userMessage);

    try {
      _setTyping(true);

      // 1. Process local database action
      String botResponse = await _engine.commandService.handleCommand(userText);

      // 2. RESTORED: Analytics extraction from JSON result
      final responseCode = _extractResponseCode(botResponse);
      if (responseCode != null) {
        Logger.cmd('Response Code: $responseCode');
        if (responseCode.startsWith('ERR')) {
          _logErrorEvent(responseCode, userText);
        }
      }

      // 3. Augment with AI if enabled and NOT a help command
      if (_isAiEnabled && !userText.toLowerCase().contains('help')) {
        final aiCommentary = await _getAiAnalysisFromWorker(
          userText,
          botResponse,
        );
        if (aiCommentary != null && aiCommentary.isNotEmpty) {
          botResponse = "$aiCommentary\n\n$botResponse";
        }
      }

      final botMessage = MessageModel(text: botResponse, isMe: false);
      await _addBotResponse(botMessage);
      await _engine.saveMessageToHistory(botMessage);
    } catch (e, stackTrace) {
      Logger.error(
        'Processing error',
        tag: 'ChatController',
        err: e,
        stack: stackTrace,
      );
      final errorMsg = MessageModel(
        text: """🚨 **Error:** Something went wrong processing your command.
*Details:* `${e.toString()}`""",
        isMe: false,
      );
      await _addBotResponse(errorMsg);
    } finally {
      _setTyping(false);
    }
  }

  Future<String?> _getAiAnalysisFromWorker(
    String userIntent,
    String dbResult,
  ) async {
    try {
      final prompt =
          """
USER INTENT: "$userIntent"
DATABASE RESULT: 
$dbResult

TASK:
You are Alison, a loyal personal assistant. 
Respond to the "Boss" in 1-2 sentences with analytical or encouraging feedback based on the result above. 
Keep it natural. Do not list JSON keys. Refer to the user as 'Boss'.
""";

      final response = await http
          .post(
            Uri.parse(_workerUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "messages": [
                {
                  "role": "system",
                  "content":
                      "You are Alison, an efficient personal assistant for 'The Boss'.",
                },
                {"role": "user", "content": prompt},
              ],
              "temperature": 0.7,
              "top_p": 1,
              "max_tokens": 512,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content']?.toString().trim();
      }
      return null;
    } catch (e) {
      Logger.error("AI Worker Request Failed", err: e);
      return null;
    }
  }

  // RESTORED: Helper to extract success/error codes from Markdown JSON blocks
  String? _extractResponseCode(String response) {
    try {
      final jsonMatch = RegExp(
        r'```json\n([\s\S]*?)\n```',
      ).firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(1);
        if (jsonStr != null) {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          return json['code'] as String?;
        }
      }
    } catch (e) {
      Logger.warn('Failed to extract response code', tag: 'ChatController');
    }
    return null;
  }

  // RESTORED: Analytics event logging
  void _logErrorEvent(String errorCode, String command) {
    Logger.error(
      'Error Event: $errorCode | Command: $command',
      tag: 'Analytics',
    );
  }

  void _addUserMessage(MessageModel message) {
    _messages.add(message);
    notifyListeners();
  }

  Future<void> _addBotResponse(MessageModel message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _messages.add(message);
    notifyListeners();
  }

  void _setTyping(bool value) {
    _isTyping = value;
    _statusMessage = value
        ? 'thinking...'
        : (_initError != null ? 'degraded' : 'online');
    notifyListeners();
  }
}
