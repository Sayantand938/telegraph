import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiResponse {
  final String? reasoning;
  final String content;

  AiResponse({this.reasoning, required this.content});
}

class NimService {
  static final NimService _instance = NimService._internal();
  factory NimService() => _instance;
  NimService._internal();

  late final String _baseUrl;
  late final String _apiKey;
  late final String _model;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await dotenv.load(fileName: ".env");
    _baseUrl = dotenv.get('BASE_URL');
    _apiKey = dotenv.get('NVIDIA_API_KEY');
    _model = dotenv.get('MODEL');
    _initialized = true;
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

    final url = '$_baseUrl/chat/completions';
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Accept': stream ? 'text/event-stream' : 'application/json',
      'Content-Type': 'application/json',
    };

    final payload = {
      'model': _model,
      'messages': [
        {'role': 'user', 'content': message},
      ],
      'max_tokens': 16384,
      'temperature': 0.60,
      'top_p': 0.95,
      'stream': stream,
      'chat_template_kwargs': {'enable_thinking': false},
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
            return AiResponse(reasoning: reasoning, content: content);
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
