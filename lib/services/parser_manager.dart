// lib/services/parser_manager.dart
import 'dart:convert';
import 'parsers/ai_parser.dart';
import 'parsers/manual_parser.dart'; // ✅ Correct relative import
import 'module_manager.dart';

class ParserManager {
  static final ParserManager _instance = ParserManager._internal();
  factory ParserManager() => _instance;
  ParserManager._internal();

  late AIParser _aiParser;
  late ManualParser _manualParser; // ✅ Now recognized
  late ModuleManager _moduleManager;
  bool _initialized = false;

  int _totalProcessed = 0;
  int _aiRouteCount = 0;
  int _manualRouteCount = 0;

  void init() {
    if (_initialized) return;
    _aiParser = AIParser();
    _manualParser = ManualParser(); // ✅ Now recognized
    _moduleManager = ModuleManager();
    _moduleManager.init();
    _initialized = true;
  }

  Future<String> processMessage(
    String message,
    DateTime timestamp,
    String dayOfWeek,
  ) async {
    if (!_initialized) init();

    _totalProcessed++;
    Map<String, dynamic> parsedData;

    if (_isManualRoute(message)) {
      _manualRouteCount++;
      parsedData = _manualParser.parse(message, timestamp, dayOfWeek);
    } else {
      _aiRouteCount++;
      parsedData = await _aiParser.parse(message, timestamp, dayOfWeek);
    }

    // ✅ Await async route (if you made ModuleManager.route async)
    final moduleResponse = await _moduleManager.route(parsedData, timestamp);

    return _formatResponse(parsedData, moduleResponse);
  }

  bool _isManualRoute(String message) {
    return message.trim().startsWith('@');
  }

  String _formatResponse(
    Map<String, dynamic> parsedData,
    String? moduleResponse,
  ) {
    final buffer = StringBuffer();
    final jsonOutput = const JsonEncoder.withIndent('  ').convert(parsedData);
    buffer.write('📦 **Parsed Data**:\n```json\n$jsonOutput\n```\n');

    if (moduleResponse != null && moduleResponse.isNotEmpty) {
      buffer.write('\n$moduleResponse');
    } else {
      buffer.write('\n⚠️ No module response');
    }
    return buffer.toString();
  }

  Map<String, dynamic> getStats() {
    return {
      'aiParser': _initialized ? 'Active' : 'Not initialized',
      'manualParser': _initialized ? 'Active' : 'Not initialized',
      'moduleManager': _initialized ? 'Active' : 'Not initialized',
      'manualTrigger': '@',
      'stats': {
        'totalProcessed': _totalProcessed,
        'aiRouteCount': _aiRouteCount,
        'manualRouteCount': _manualRouteCount,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  void resetStats() {
    _totalProcessed = 0;
    _aiRouteCount = 0;
    _manualRouteCount = 0;
  }
}
