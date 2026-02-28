import 'package:flutter/foundation.dart';
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
    _logInit();
  }

  void _logInit() {
    if (!kDebugMode) return;
    debugPrint('🚀 ParserManager initialized');
    debugPrint('   ├─ AI Parser:    Active (default route)');
    debugPrint('   └─ Manual Parser: Active (@ prefix route)');
  }

  /// Route message to appropriate parser
  void processMessage(String message, DateTime timestamp) {
    if (!_initialized) init();

    _totalProcessed++;

    if (_isManualRoute(message)) {
      _manualRouteCount++;
      _manualParser.parse(message, timestamp);
    } else {
      _aiRouteCount++;
      _aiParser.parse(message, timestamp);
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
