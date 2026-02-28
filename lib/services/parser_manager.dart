// lib/services/parser_manager.dart
import 'parsers/ai_parser.dart';
import 'parsers/manual_parser.dart';
import 'module_manager.dart';

class ParserManager {
  static final ParserManager _instance = ParserManager._internal();
  factory ParserManager() => _instance;
  ParserManager._internal();

  late AIParser _aiParser;
  late ManualParser _manualParser;
  late ModuleManager _moduleManager;
  bool _initialized = false;

  int _totalProcessed = 0;
  int _aiRouteCount = 0;
  int _manualRouteCount = 0;

  void init() {
    if (_initialized) return;
    _aiParser = AIParser();
    _manualParser = ManualParser();
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

    // ✅ Await async route
    final moduleResponse = await _moduleManager.route(parsedData, timestamp);

    // ✅ Only return meaningful feedback (no JSON debug output)
    return _formatResponse(moduleResponse);
  }

  bool _isManualRoute(String message) {
    return message.trim().startsWith('@');
  }

  /// ✅ Clean response: Only show module feedback, no debug JSON
  String _formatResponse(String? moduleResponse) {
    if (moduleResponse != null && moduleResponse.isNotEmpty) {
      return moduleResponse;
    }
    return '⚠️ No response from module';
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
