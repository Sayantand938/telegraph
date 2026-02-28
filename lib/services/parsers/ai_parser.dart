import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'base_parser.dart';

/// Parser for AI-processed messages
/// AI determines target_module and action from natural language
/// Expects Worker to return structured JSON (not stringified)
class AIParser extends BaseParser {
  static const String _workerUrl =
      'https://telegraph-ai-worker.sayantand938.workers.dev/';

  AIParser() : super('AI Parser');

  @override
  Future<Map<String, dynamic>> parse(String message, DateTime timestamp) async {
    try {
      // Prepare payload
      final payload = jsonEncode({
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      });

      // Send request to Cloudflare Worker
      final response = await http
          .post(
            Uri.parse(_workerUrl),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 30));

      // Handle non-200 responses
      if (response.statusCode != 200) {
        debugPrint('❌ Worker error: ${response.statusCode} - ${response.body}');
        return _errorResponse(
          message,
          'Worker returned status ${response.statusCode}',
        );
      }

      // Parse worker response
      final responseData = jsonDecode(response.body);

      if (responseData is! Map<String, dynamic>) {
        debugPrint('❌ Invalid response format: ${response.body}');
        return _errorResponse(
          message,
          'Invalid response format from AI service',
        );
      }

      // ✅ Ensure standard fields exist for ModuleManager routing
      return _normalizeResponse(responseData, message);
    } on TimeoutException {
      debugPrint('⏱️ AI service timeout');
      return _errorResponse(message, 'AI service timeout');
    } on http.ClientException catch (e) {
      debugPrint('🔍 Network error: $e');
      return _errorResponse(message, 'Network error: $e');
    } on FormatException catch (e) {
      debugPrint('🔍 JSON parse error: $e');
      return _errorResponse(message, 'Failed to parse AI response');
    } catch (e) {
      debugPrint('🔍 Unexpected error: $e');
      return _errorResponse(message, e.toString());
    }
  }

  /// Normalize AI response to ensure required fields for ModuleManager
  Map<String, dynamic> _normalizeResponse(
    Map<String, dynamic> responseData,
    String originalMessage,
  ) {
    // If AI returned a nested 'response' field that's a string, try to parse it
    // (Fallback for backwards compatibility or edge cases)
    if (responseData.containsKey('response')) {
      final responseField = responseData['response'];
      if (responseField is String) {
        try {
          final parsed = jsonDecode(responseField);
          if (parsed is Map<String, dynamic>) {
            responseData.addAll(parsed);
          }
        } catch (_) {
          // Keep as-is if parsing fails
        }
      } else if (responseField is Map<String, dynamic>) {
        responseData.addAll(responseField);
      }
    }

    // Ensure required fields exist
    return {
      'target_module': responseData['target_module'] ?? 'chat',
      'action': responseData['action'] ?? 'respond',
      'source': 'ai',
      'original_message': originalMessage,
      'worker_timestamp':
          responseData['worker_timestamp'] ?? DateTime.now().toIso8601String(),
      'success': responseData['success'] ?? true,
      // Include all other fields from AI (note, tags, content, etc.)
      ...responseData,
    }..remove('response'); // Remove duplicate 'response' key if merged
  }

  /// Create standardized error response
  Map<String, dynamic> _errorResponse(String originalMessage, String error) {
    return {
      'target_module': 'chat',
      'action': 'error',
      'source': 'ai',
      'original_message': originalMessage,
      'error': error,
      'success': false,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
