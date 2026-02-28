import 'parsers/ai_parser.dart';
import 'parsers/manual_parser.dart';

/// Main router that delegates to appropriate parser
class ParserManager {
  // Singleton
  static final ParserManager _instance = ParserManager._internal();
  factory ParserManager() => _instance;
  ParserManager._internal();

  // Parser instances
  late AIParser _aiParser;
  late ManualParser _manualParser;
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
    _initialized = true;
  }

  /// Route message to appropriate parser and return formatted response
  Future<String> processMessage(String message, DateTime timestamp) async {
    if (!_initialized) init();

    _totalProcessed++;

    if (_isManualRoute(message)) {
      _manualRouteCount++;
      return await _manualParser.parse(message, timestamp);
    } else {
      _aiRouteCount++;
      return await _aiParser.parse(message, timestamp);
    }
  }

  /// Check if message should go to manual parser
  bool _isManualRoute(String message) {
    return message.trim().startsWith('@');
  }

  /// Get parser stats (for debugging/UI)
  Map<String, dynamic> getStats() {
    return {
      'aiParser': _initialized ? 'Active' : 'Not initialized',
      'manualParser': _initialized ? 'Active' : 'Not initialized',
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