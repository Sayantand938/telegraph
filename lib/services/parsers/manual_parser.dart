import 'dart:convert';
import 'base_parser.dart';
import '../module_manager.dart';

class ManualParser extends BaseParser {
  final ModuleManager _moduleManager = ModuleManager();

  ManualParser() : super('Manual Parser');

  @override
  Future<String> parse(String message, DateTime timestamp) async {
    // Initialize module manager (idempotent)
    _moduleManager.init();

    // Strip @ prefix and trim whitespace
    final cleaned = stripManualTrigger(message);

    // Parse into structured Map
    final parsedData = _parseCommandMessage(cleaned);

    // Handle parse failure
    if (parsedData.isEmpty) {
      return '❌ Failed to parse command. Use format: `module --key value`';
    }

    // Add routing metadata
    parsedData['_route'] = 'manual';
    parsedData['_timestamp'] = timestamp.toIso8601String();

    // Route to ModuleManager for business logic (silent)
    _moduleManager.route(parsedData, timestamp);

    // Format clean JSON output for UI (exclude internal metadata)
    final jsonOutput = _formatJsonOutput(parsedData);
    
    return '✅ **$message**\n\n📦 Parsed Output:\n```json\n$jsonOutput\n```';
  }

  Map<String, dynamic> _parseCommandMessage(String message) {
    final result = <String, dynamic>{};
    final trimmed = message.trim();

    if (trimmed.isEmpty) return result;

    final tokens = _tokenize(trimmed);
    if (tokens.isEmpty) return result;

    result['target_module'] = tokens[0];

    int i = 1;
    while (i < tokens.length) {
      final token = tokens[i];

      if (token.startsWith('--')) {
        final key = token.substring(2);
        i++;

        final valueParts = <String>[];
        while (i < tokens.length && !tokens[i].startsWith('--')) {
          valueParts.add(tokens[i]);
          i++;
        }

        if (valueParts.isEmpty) {
          result[key] = true;
        } else {
          final rawValue = valueParts.join(' ');

          if (key == 'tags') {
            if (rawValue.contains(',')) {
              result[key] = rawValue
                  .split(',')
                  .map((v) => v.trim())
                  .where((v) => v.isNotEmpty)
                  .toList();
            } else {
              result[key] = [rawValue.trim()];
            }
          } else if (rawValue.contains(',')) {
            result[key] = rawValue
                .split(',')
                .map((v) => v.trim())
                .where((v) => v.isNotEmpty)
                .toList();
          } else {
            result[key] = _parseValue(rawValue);
          }
        }
      } else {
        i++;
      }
    }

    return result;
  }

  List<String> _tokenize(String message) {
    return message.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }

  dynamic _parseValue(String value) {
    final trimmed = value.trim();
    final lower = trimmed.toLowerCase();

    if (lower == 'true') return true;
    if (lower == 'false') return false;

    final numVal = num.tryParse(trimmed);
    if (numVal != null) return numVal;

    return trimmed;
  }

  /// Format JSON with indentation for UI display
  String _formatJsonOutput(Map<String, dynamic> data) {
    final exportData = Map<String, dynamic>.from(data);
    exportData.remove('_route');
    exportData.remove('_timestamp');
    return JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Export parsed data as clean JSON string (without internal metadata)
  String toJsonString(Map<String, dynamic> data) {
    final exportData = Map<String, dynamic>.from(data);
    exportData.remove('_route');
    exportData.remove('_timestamp');
    return jsonEncode(exportData);
  }
}