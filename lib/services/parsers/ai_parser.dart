import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // for debugPrint
import 'base_parser.dart';

/// Parser for AI-processed messages (default route)
/// Sends messages to Cloudflare Worker for AI processing
class AIParser extends BaseParser {
  static const String _workerUrl = 
      'https://telegraph-ai-worker.sayantand938.workers.dev/';
  
  AIParser() : super('AI Parser');

  @override
  Future<String> parse(String message, DateTime timestamp) async {
    try {
      final payload = jsonEncode({
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      });

      final response = await http.post(
        Uri.parse(_workerUrl),
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // ✅ Extract response from Worker's JSON format
        String aiResponse;
        if (responseData is Map<String, dynamic>) {
          aiResponse = responseData['response'] 
              ?? responseData['message'] 
              ?? responseData['text']
              ?? 'No content received';
        } else if (responseData is String) {
          aiResponse = responseData;
        } else {
          aiResponse = response.body;
        }
        
        return '🤖 **AI Response**\n\n$aiResponse';
        
      } else {
        // Try to parse error from Worker
        String errorDetail = '';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic>) {
            errorDetail = errorData['error'] ?? 'Unknown error';
          }
        } catch (_) {}
        
        return '❌ **Worker Error**\n\n'
            'Status: ${response.statusCode}\n'
            '${errorDetail.isNotEmpty ? 'Details: $errorDetail\n\n' : ''}'
            '💡 Try `@` commands for instant Manual Parser mode.';
      }
      
    } on TimeoutException {
      return '⏱️ **Timeout**\n\n'
          'AI service is taking too long.\n\n'
          'Try: `@time start --note "Work"` for instant manual mode.';
          
    } on http.ClientException catch (e) {
      debugPrint('🔍 Network error: $e');
      return '❌ **Network Error**\n\n'
          'Could not connect to AI service.\n\n'
          '💡 Tip: Start with `@` for Manual Parser (works offline)';
          
    } on FormatException catch (e) {
      debugPrint('🔍 Parse error: $e');
      return '❌ **Response Error**\n\n'
          'Could not parse AI response.\n\n'
          '💡 Try again or use `@` commands.';
          
    } catch (e) {
      debugPrint('🔍 Unexpected error: $e');
      return '❌ **Error**\n\n'
          '$e\n\n'
          'Try `@task add --title "Test"` for manual mode.';
    }
  }
}