import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:telegraph/services/tools/tool_service.dart';
import 'package:get_it/get_it.dart';

class AiResponse {
  final String? reasoning;
  final String content;
  final List<Map<String, dynamic>>? toolCalls;

  AiResponse({this.reasoning, required this.content, this.toolCalls});
}

class LlmService {
  static final LlmService _instance = LlmService._internal();
  factory LlmService() => _instance;
  LlmService._internal();

  late final String _baseUrl;
  late final String _apiKey;
  late final String _model;

  bool _initialized = false;
  final List<Map<String, dynamic>> _conversationHistory = [];

  Future<void> initialize() async {
    if (_initialized) return;

    await dotenv.load(fileName: ".env");
    _baseUrl = dotenv.get('BASE_URL');
    _apiKey = dotenv.get('NVIDIA_API_KEY');
    _model = dotenv.get('MODEL');
    _initialized = true;
  }

  void clearHistory() {
    _conversationHistory.clear();
  }

  void _addToHistory(String role, String content) {
    _conversationHistory.add({'role': role, 'content': content});
  }

  Future<bool> healthCheck() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final url = '$_baseUrl/models';
      final headers = {
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'application/json',
      };

      final response = await http.get(Uri.parse(url), headers: headers);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  String getModelName() {
    if (!_initialized) {
      throw Exception('Service not initialized. Call initialize() first.');
    }
    return _model;
  }

  Future<AiResponse> sendMessage(String message, {bool stream = false}) async {
    if (!_initialized) {
      await initialize();
    }

    // Add user message to history
    _conversationHistory.add({'role': 'user', 'content': message});

    final url = '$_baseUrl/chat/completions';
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Accept': stream ? 'text/event-stream' : 'application/json',
      'Content-Type': 'application/json',
    };

    final toolService = GetIt.instance<ToolService>();
    final tools = toolService.getToolSchemas();

    final payload = {
      'model': _model,
      'messages': List.from(_conversationHistory),
      'max_tokens': 16384,
      'temperature': 0.60,
      'top_p': 0.95,
      'stream': stream,
      'chat_template_kwargs': {'enable_thinking': false},
      if (tools.isNotEmpty) 'tools': tools,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        if (stream) {
          final content = await _handleStreamingResponse(response);
          return AiResponse(content: content);
        } else {
          final data = jsonDecode(response.body);
          if (data['choices'] != null &&
              data['choices'].isNotEmpty &&
              data['choices'][0]['message'] != null) {
            final message = data['choices'][0]['message'];
            final content = message['content'] ?? '';
            final reasoning = message['reasoning_content'];
            final toolCalls = message['tool_calls'] as List<dynamic>?;

            // If there are tool calls, execute them
            if (toolCalls != null && toolCalls.isNotEmpty) {
              final executedResults = await _executeToolCalls(
                toolCalls,
                toolService,
              );
              // Send tool results back to AI for final response
              return await _sendToolResults(executedResults, message);
            }

            return AiResponse(
              reasoning: reasoning,
              content: content,
              toolCalls: null,
            );
          }
          return AiResponse(content: 'No response generated');
        }
      } else {
        return AiResponse(
          content: 'Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      return AiResponse(content: 'Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _executeToolCalls(
    List<dynamic> toolCalls,
    ToolService toolService,
  ) async {
    final results = <Map<String, dynamic>>[];

    for (final toolCall in toolCalls) {
      final function = toolCall['function'];
      final toolName = function['name'];
      final argumentsJson = function['arguments'];

      try {
        final args = jsonDecode(argumentsJson) as Map<String, dynamic>;
        final result = await toolService.executeTool(toolName, args);
        results.add({
          'tool_call_id': toolCall['id'],
          'tool_name': toolName,
          'result': result,
        });
      } catch (e) {
        results.add({
          'tool_call_id': toolCall['id'],
          'tool_name': toolName,
          'result': 'Error executing tool: $e',
        });
      }
    }

    return results;
  }

  Future<AiResponse> _sendToolResults(
    List<Map<String, dynamic>> results,
    Map<String, dynamic> originalMessage,
  ) async {
    // Add the assistant's message with tool calls to history
    _addToHistory('assistant', originalMessage['content'] ?? '');

    // Add tool response messages to history
    for (final result in results) {
      _addToHistory('tool', result['result'].toString());
    }

    // Make another API call to get final response using updated history
    final url = '$_baseUrl/chat/completions';
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final toolService = GetIt.instance<ToolService>();
    final tools = toolService.getToolSchemas();

    final payload = {
      'model': _model,
      'messages': List.from(_conversationHistory),
      'max_tokens': 16384,
      'temperature': 0.60,
      'top_p': 0.95,
      'stream': false,
      'chat_template_kwargs': {'enable_thinking': false},
      if (tools.isNotEmpty) 'tools': tools,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null &&
            data['choices'].isNotEmpty &&
            data['choices'][0]['message'] != null) {
          final message = data['choices'][0]['message'];
          final content = message['content'] ?? '';
          final reasoning = message['reasoning_content'];
          // Add final assistant response to history
          _addToHistory('assistant', content);
          return AiResponse(reasoning: reasoning, content: content);
        }
        return AiResponse(
          content: 'No response generated after tool execution',
        );
      } else {
        return AiResponse(
          content: 'Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      return AiResponse(content: 'Error: $e');
    }
  }

  Future<String> _handleStreamingResponse(http.Response response) async {
    final StringBuffer buffer = StringBuffer();
    final lines = response.body.split('\n');

    for (final line in lines) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6);
        if (data == '[DONE]') continue;

        try {
          final jsonData = jsonDecode(data);
          if (jsonData['choices'] != null &&
              jsonData['choices'].isNotEmpty &&
              jsonData['choices'][0]['delta'] != null) {
            final delta = jsonData['choices'][0]['delta'];
            final content = delta['content'];
            if (content != null) {
              buffer.write(content);
            }
          }
        } catch (e) {
          // Skip malformed JSON lines
        }
      }
    }

    return buffer.toString();
  }
}
