import 'dart:convert';
import 'parsers/ai_parser.dart';
import 'parsers/manual_parser.dart';
import 'module_manager.dart';

/// Main router that delegates to appropriate parser, then routes to modules
class ParserManager {
  // Singleton
  static final ParserManager _instance = ParserManager._internal();
  factory ParserManager() => _instance;
  ParserManager._internal();

  // Parser instances
  late AIParser _aiParser;
  late ManualParser _manualParser;
  late ModuleManager _moduleManager;
  bool _initialized = false;

  // Stats tracking
  int _totalProcessed = 0;
  int _aiRouteCount = 0;
  int _manualRouteCount = 0;

  /// Initialization
  void init() {
    if (_initialized) return;
    _aiParser = AIParser();
    _manualParser = ManualParser();
    _moduleManager = ModuleManager();
    _moduleManager.init();
    _initialized = true;
  }

  /// Route message to appropriate parser, then to module manager
  Future<String> processMessage(
    String message,
    DateTime timestamp,
    String dayOfWeek,
  ) async {
    if (!_initialized) init();

    _totalProcessed++;

    Map<String, dynamic> parsedData;

    // Step 1: Parse message (AI or Manual)
    if (_isManualRoute(message)) {
      _manualRouteCount++;
      parsedData = await _manualParser.parse(message, timestamp, dayOfWeek);
    } else {
      _aiRouteCount++;
      parsedData = await _aiParser.parse(message, timestamp, dayOfWeek);
    }

    // Step 2: Route to ModuleManager based on target_module
    final moduleResponse = _moduleManager.route(parsedData, timestamp);

    // Step 3: Format final response for UI
    return _formatResponse(parsedData, moduleResponse);
  }

  /// Check if message should go to manual parser
  bool _isManualRoute(String message) {
    return message.trim().startsWith('@');
  }

  /// Format parsed data + module response into markdown
  String _formatResponse(
    Map<String, dynamic> parsedData,
    String? moduleResponse,
  ) {
    final buffer = StringBuffer();

    // Show parsed JSON (for debugging/transparency)
    final jsonOutput = const JsonEncoder.withIndent('  ').convert(parsedData);
    buffer.write('📦 **Parsed Data**:\n```json\n$jsonOutput\n```\n');

    // Show module response
    if (moduleResponse != null && moduleResponse.isNotEmpty) {
      buffer.write('\n$moduleResponse');
    } else {
      buffer.write(
        '\n⚠️ No module response (module may not exist or action not recognized)',
      );
    }

    return buffer.toString();
  }

  /// Get parser stats (for debugging/UI)
  Map<String, dynamic> getStats() {
    return {
      'aiParser': _initialized ? 'Active' : 'Not initialized',
      'manualParser': _initialized ? 'Active' : 'Not initialized',
      'moduleManager': _initialized ? 'Active' : 'Not initialized',
      'manualTrigger': '@',
      'workerUrl': 'https://telegraph-ai-worker.sayantand938.workers.dev/',
      'stats': {
        'totalProcessed': _totalProcessed,
        'aiRouteCount': _aiRouteCount,
        'manualRouteCount': _manualRouteCount,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Reset stats (for testing)
  void resetStats() {
    _totalProcessed = 0;
    _aiRouteCount = 0;
    _manualRouteCount = 0;
  }
}
