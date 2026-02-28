import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'base_parser.dart';

/// Dumb AI Parser
/// Returns raw JSON from worker + minimal envelope. No field enforcement.
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
          'source': 'ai',
          'error': 'Worker status ${response.statusCode}',
        };
      }

      final responseData = jsonDecode(response.body);
      if (responseData is! Map<String, dynamic>) {
        return {'source': 'ai', 'error': 'Invalid response format'};
      }

      // ✅ Envelope raw data with minimal context, do not constrain fields
      return {
        'source': 'ai',
        'timestamp': timestamp.toIso8601String(),
        'day_of_week': dayOfWeek,
        ...responseData, // Spread all AI-generated fields directly
      };
    } catch (e) {
      return {'source': 'ai', 'error': e.toString()};
    }
  }
}
