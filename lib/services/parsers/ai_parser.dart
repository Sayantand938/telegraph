import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_parser.dart';

/// AI Parser that mirrors the worker output
/// Assumes worker already returns only JSON with all AI fields
class AIParser extends BaseParser {
  static const String _workerUrl =
      'https://telegraph-ai-worker.sayantand938.workers.dev/';

  AIParser() : super('AI Parser');

  @override
  Future<Map<String, dynamic>> parse(
    String message,
    DateTime timestamp,
    String dayOfWeek,
  ) async {
    try {
      final payload = jsonEncode({
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'day_of_week': dayOfWeek,
      });

      final response = await http
          .post(
            Uri.parse(_workerUrl),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return {
          'target_module': 'chat',
          'action': 'error',
          'error': 'Worker status ${response.statusCode}',
        };
      }

      final responseData = jsonDecode(response.body);
      if (responseData is! Map<String, dynamic>) {
        return {
          'target_module': 'chat',
          'action': 'error',
          'error': 'Invalid response format',
        };
      }

      // ✅ Envelope: add timestamp and day_of_week
      responseData['timestamp'] = timestamp.toIso8601String();
      responseData['day_of_week'] = dayOfWeek;

      // ✅ Safeguard: ensure target_module exists
      if (!responseData.containsKey('target_module')) {
        responseData['target_module'] = 'chat';
      }

      return responseData;
    } catch (e) {
      return {
        'target_module': 'chat',
        'action': 'error',
        'error': e.toString(),
      };
    }
  }
}
