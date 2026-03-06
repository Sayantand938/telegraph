// lib/features/chat/services/command_service.dart
import 'package:flutter/foundation.dart';
import 'package:telegraph/core/module_interface.dart';
import 'package:telegraph/core/utils/command_parser.dart';
import 'package:telegraph/core/utils/response_formatter.dart';

class CommandService {
  final Map<String, FeatureCommandHandler> _handlers;

  CommandService(List<FeatureCommandHandler> handlerList)
    : _handlers = _buildHandlerMap(handlerList);

  static Map<String, FeatureCommandHandler> _buildHandlerMap(
    List<FeatureCommandHandler> handlers,
  ) {
    final map = <String, FeatureCommandHandler>{};
    for (var h in handlers) {
      // ✅ Use explicit moduleKey instead of scanning helpText
      final key = h.moduleKey;
      if (key.isNotEmpty) {
        map[key] = h;
      }
    }
    return map;
  }

  Future<String> handleCommand(String input) async {
    final parsed = ParsedCommand.parse(input);

    if (parsed.module.isEmpty) {
      return _getAggregatedHelp();
    }

    final handler = _handlers[parsed.module];
    if (handler == null) {
      return ResponseFormatter.error('Unknown module: ${parsed.module}');
    }

    try {
      return await handler.handle(input);
    } catch (e, stackTrace) {
      debugPrint('Command error: $e\n$stackTrace');
      return ResponseFormatter.error(
        'Something went wrong',
        details: {
          'module': parsed.module,
          'action': parsed.action,
          'error': e.toString(),
        },
      );
    }
  }

  String _getAggregatedHelp() {
    String help = "🤖 **Alison CLI**\n";
    for (var handler in _handlers.values) {
      help += "${handler.helpText}\n";
    }
    return help;
  }
}
