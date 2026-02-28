import 'dart:convert';
import 'base_parser.dart';
import '../module_manager.dart';

class ManualParser extends BaseParser {
  final ModuleManager _moduleManager = ModuleManager();

  ManualParser() : super('Manual Parser');

  @override
  void parse(String message, DateTime timestamp) {
    // Initialize module manager (idempotent)
    _moduleManager.init();

    // Strip @ prefix and trim whitespace
    final cleaned = stripManualTrigger(message);

    // Parse into structured Map
    final parsedData = _parseCommandMessage(cleaned);

    // Handle parse failure
    if (parsedData.isEmpty) {
      log(message, timestamp, metadata: '❌ Failed to parse command');
      return;
    }

    // Add routing metadata (for debugging/tracing)
    parsedData['_route'] = 'manual';
    parsedData['_timestamp'] = timestamp.toIso8601String();

    // Log with structured JSON output
    final jsonOutput = jsonEncode(parsedData);
    log(
      message,
      timestamp,
      metadata: 'Module: ${parsedData['target_module']} | JSON: $jsonOutput',
    );

    // Route to ModuleManager for business logic handling
    _moduleManager.route(parsedData, timestamp);
  }

  Map<String, dynamic> _parseCommandMessage(String message) {
    final result = <String, dynamic>{};
    final trimmed = message.trim();

    if (trimmed.isEmpty) return result;

    // Tokenize: split by whitespace, preserve --flags
    final tokens = _tokenize(trimmed);
    if (tokens.isEmpty) return result;

    // First token is always the target module
    result['target_module'] = tokens[0];

    // Parse remaining --key value pairs
    int i = 1;
    while (i < tokens.length) {
      final token = tokens[i];

      if (token.startsWith('--')) {
        final key = token.substring(2); // Remove '--' prefix
        i++;

        // Collect all value tokens until next --flag or end of input
        final valueParts = <String>[];
        while (i < tokens.length && !tokens[i].startsWith('--')) {
          valueParts.add(tokens[i]);
          i++;
        }

        if (valueParts.isEmpty) {
          // Boolean flag with no value: --verbose → true
          result[key] = true;
        } else {
          final rawValue = valueParts.join(' ');

          // Special handling for 'tags' key: always return as List
          if (key == 'tags') {
            if (rawValue.contains(',')) {
              // Comma-separated: "a, b, c" → ["a", "b", "c"]
              result[key] = rawValue
                  .split(',')
                  .map((v) => v.trim())
                  .where((v) => v.isNotEmpty)
                  .toList();
            } else {
              // Single value: "chicken" → ["chicken"] (consistent List)
              result[key] = [rawValue.trim()];
            }
          }
          // Comma-separated values for other keys → List
          else if (rawValue.contains(',')) {
            result[key] = rawValue
                .split(',')
                .map((v) => v.trim())
                .where((v) => v.isNotEmpty)
                .toList();
          }
          // Single value → smart type conversion
          else {
            result[key] = _parseValue(rawValue);
          }
        }
      } else {
        // Skip unexpected tokens (shouldn't occur with valid syntax)
        i++;
      }
    }

    return result;
  }

  /// Simple tokenizer: split by any whitespace
  List<String> _tokenize(String message) {
    return message.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }

  /// Smart value parser: detect numbers, booleans, or keep as string
  dynamic _parseValue(String value) {
    final trimmed = value.trim();
    final lower = trimmed.toLowerCase();

    // Boolean literals
    if (lower == 'true') return true;
    if (lower == 'false') return false;

    // Numeric values (int or double)
    final numVal = num.tryParse(trimmed);
    if (numVal != null) return numVal;

    // Default: return as string
    return trimmed;
  }

  /// Export parsed data as clean JSON string (without internal metadata)
  String toJsonString(Map<String, dynamic> data) {
    final exportData = Map<String, dynamic>.from(data);
    exportData.remove('_route');
    exportData.remove('_timestamp');
    return jsonEncode(exportData);
  }
}
