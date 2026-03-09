import 'dart:convert';
import 'package:http/http.dart' as http;

/// Request object for LLM API calls
class LlmRequest {
  final String message;
  final List<LlmMessage>? conversationHistory;
  final List<LlmToolSchema>? tools;
  final bool stream;
  final int maxTokens;
  final double temperature;
  final double topP;
  final bool enableThinking;

  LlmRequest({
    required this.message,
    this.conversationHistory,
    this.tools,
    this.stream = false,
    this.maxTokens = 16384,
    this.temperature = 0.60,
    this.topP = 0.95,
    this.enableThinking = false,
  });

  Map<String, dynamic> toJson() {
    final messages = conversationHistory ?? [LlmMessage.user(message)];

    return {
      'model': '', // Will be set by client from config
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'max_tokens': maxTokens,
      'temperature': temperature,
      'top_p': topP,
      'stream': stream,
      'chat_template_kwargs': {'enable_thinking': enableThinking},
      if (tools != null && tools!.isNotEmpty)
        'tools': tools!.map((t) => t.toJson()).toList(),
    };
  }
}

/// Message in conversation history
class LlmMessage {
  final String role;
  final String content;
  final String? reasoningContent;
  final List<LlmToolCall>? toolCalls;

  LlmMessage({
    required this.role,
    required this.content,
    this.reasoningContent,
    this.toolCalls,
  });

  factory LlmMessage.user(String content) =>
      LlmMessage(role: 'user', content: content);
  factory LlmMessage.assistant(
    String content, {
    String? reasoning,
    List<LlmToolCall>? toolCalls,
  }) => LlmMessage(
    role: 'assistant',
    content: content,
    reasoningContent: reasoning,
    toolCalls: toolCalls,
  );
  factory LlmMessage.tool(String content) =>
      LlmMessage(role: 'tool', content: content);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'role': role, 'content': content};
    if (reasoningContent != null) {
      map['reasoning_content'] = reasoningContent;
    }
    if (toolCalls != null && toolCalls!.isNotEmpty) {
      map['tool_calls'] = toolCalls!.map((tc) => tc.toJson()).toList();
    }
    return map;
  }

  factory LlmMessage.fromJson(Map<String, dynamic> json) {
    return LlmMessage(
      role: json['role'] as String,
      content: json['content'] as String? ?? '',
      reasoningContent: json['reasoning_content'] as String?,
      toolCalls: json['tool_calls'] != null
          ? (json['tool_calls'] as List<dynamic>)
                .map((tc) => LlmToolCall.fromJson(tc as Map<String, dynamic>))
                .toList()
          : null,
    );
  }
}

/// Tool call from LLM response
class LlmToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  LlmToolCall({required this.id, required this.name, required this.arguments});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'function': {'name': name, 'arguments': jsonEncode(arguments)},
    };
  }

  factory LlmToolCall.fromJson(Map<String, dynamic> json) {
    final function = json['function'] as Map<String, dynamic>;
    final argsJson = function['arguments'] as String;
    return LlmToolCall(
      id: json['id'] as String,
      name: function['name'] as String,
      arguments: jsonDecode(argsJson) as Map<String, dynamic>,
    );
  }
}

/// Tool schema for LLM function calling
class LlmToolSchema {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  LlmToolSchema({
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': parameters,
      },
    };
  }
}

/// Response from LLM API
class LlmResponse {
  final String content;
  final String? reasoning;
  final List<LlmToolCall>? toolCalls;
  final bool isStreaming;

  LlmResponse({
    required this.content,
    this.reasoning,
    this.toolCalls,
    this.isStreaming = false,
  });

  factory LlmResponse.fromJson(Map<String, dynamic> json) {
    final choices = json['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      return LlmResponse(content: 'No response generated');
    }

    final message = choices[0]['message'] as Map<String, dynamic>?;
    if (message == null) {
      return LlmResponse(content: 'No response generated');
    }

    final content = message['content'] as String? ?? '';
    final reasoning = message['reasoning_content'] as String?;
    final toolCalls = message['tool_calls'] as List<dynamic>?;

    return LlmResponse(
      content: content,
      reasoning: reasoning,
      toolCalls: toolCalls
          ?.map((tc) => LlmToolCall.fromJson(tc as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Interface for LLM client
abstract class ILlmClient {
  Future<LlmResponse> sendMessage(LlmRequest request);
  Future<bool> healthCheck();
  String get modelName;
}

/// HTTP client for LLM API
class LlmClient implements ILlmClient {
  final String baseUrl;
  final String apiKey;
  final String model;

  LlmClient({required this.baseUrl, required this.apiKey, required this.model});

  @override
  Future<LlmResponse> sendMessage(LlmRequest request) async {
    final url = '$baseUrl/chat/completions';
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Accept': request.stream ? 'text/event-stream' : 'application/json',
      'Content-Type': 'application/json',
    };

    // Add model to request
    final jsonBody = request.toJson();
    jsonBody['model'] = model;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode == 200) {
        if (request.stream) {
          final content = await _handleStreamingResponse(response);
          return LlmResponse(content: content, isStreaming: true);
        } else {
          return LlmResponse.fromJson(jsonDecode(response.body));
        }
      } else {
        throw LlmClientException(
          'HTTP ${response.statusCode}: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is LlmClientException) rethrow;
      throw LlmClientException('Failed to send message: $e');
    }
  }

  @override
  Future<bool> healthCheck() async {
    try {
      final url = '$baseUrl/models';
      final headers = {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      };

      final response = await http.get(Uri.parse(url), headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  String get modelName => model;

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

/// Exception thrown by LlmClient
class LlmClientException implements Exception {
  final String message;
  final int? statusCode;

  LlmClientException(this.message, {this.statusCode});

  @override
  String toString() =>
      'LlmClientException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}
