import 'base_parser.dart';

/// Dumb Manual Parser
/// Extracts key-value pairs. Does not enforce specific fields like 'action'.
class ManualParser extends BaseParser {
  ManualParser() : super('Manual Parser');

  @override
  Future<Map<String, dynamic>> parse(
    String message,
    DateTime timestamp,
    String dayOfWeek,
  ) async {
    final cleaned = stripManualTrigger(message);
    final tokens = _tokenize(cleaned);
    final result = <String, dynamic>{};

    // ✅ Extract potential module from first token (syntax parsing)
    if (tokens.isNotEmpty) {
      result['target_module'] = tokens[0];
    }

    // ✅ Parse remaining flags (--key value)
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
        result[key] = valueParts.isEmpty
            ? true
            : _parseValue(valueParts.join(' '));
      } else {
        // Non-flag tokens are just passed as data (e.g., action)
        if (!result.containsKey('action')) {
          result['action'] = token;
        }
        i++;
      }
    }

    // ✅ Envelope with minimal context
    return {
      'source': 'manual',
      'timestamp': timestamp.toIso8601String(),
      'day_of_week': dayOfWeek,
      ...result,
    };
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
