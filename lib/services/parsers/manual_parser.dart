import 'base_parser.dart';

/// Parser for manually triggered commands (@ prefix)
/// Extracts target_module and key-value pairs from command syntax
class ManualParser extends BaseParser {
  ManualParser() : super('Manual Parser');

  @override
  Future<Map<String, dynamic>> parse(String message, DateTime timestamp) async {
    final cleaned = stripManualTrigger(message);
    final parsedData = _extractKeyValuePairs(cleaned);

    // Ensure standard fields exist
    if (!parsedData.containsKey('source')) {
      parsedData['source'] = 'manual';
    }
    if (!parsedData.containsKey('original_message')) {
      parsedData['original_message'] = message;
    }
    if (!parsedData.containsKey('timestamp')) {
      parsedData['timestamp'] = timestamp.toIso8601String();
    }

    return parsedData;
  }

  Map<String, dynamic> _extractKeyValuePairs(String message) {
    final result = <String, dynamic>{};
    final tokens = _tokenize(message);

    if (tokens.isEmpty) {
      result['target_module'] = 'chat';
      result['action'] = 'unknown';
      return result;
    }

    // First token is target module
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
          result[key] = _parseValue(valueParts.join(' '));
        }
      } else {
        // First non-flag token after module is action
        if (!result.containsKey('action')) {
          result['action'] = token;
        }
        i++;
      }
    }

    // Default action if not specified
    if (!result.containsKey('action')) {
      result['action'] = 'default';
    }

    return result;
  }

  List<String> _tokenize(String message) {
    final tokens = <String>[];
    final regex = RegExp(r'"[^"]*"|\S+');

    for (final match in regex.allMatches(message)) {
      var token = match.group(0)!;
      if (token.startsWith('"') && token.endsWith('"') && token.length >= 2) {
        token = token.substring(1, token.length - 1);
      }
      if (token.isNotEmpty) tokens.add(token);
    }
    return tokens;
  }

  dynamic _parseValue(String value) {
    final trimmed = value.trim();
    final lower = trimmed.toLowerCase();

    if (lower == 'true') return true;
    if (lower == 'false') return false;

    final numVal = num.tryParse(trimmed);
    if (numVal != null) return numVal;

    if (trimmed.contains(',')) {
      return trimmed
          .split(',')
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .toList();
    }

    return trimmed;
  }
}
