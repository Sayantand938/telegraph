import 'dart:convert';
import 'base_parser.dart';
import '../module_manager.dart';

class ManualParser extends BaseParser {
  final ModuleManager _moduleManager = ModuleManager();

  ManualParser() : super('Manual Parser');

  @override
  Future<String> parse(String message, DateTime timestamp) async {
    _moduleManager.init();
    final cleaned = stripManualTrigger(message);
    final parsedData = _extractKeyValuePairs(cleaned);

    if (parsedData.isEmpty) {
      return '❌ Failed to parse. Use: `@module --key value`';
    }

    final moduleResponse = _moduleManager.route(parsedData, timestamp);
    final jsonOutput = const JsonEncoder.withIndent('  ').convert(parsedData);

    final buffer = StringBuffer();
    buffer.write('✅ **$message**\n\n📦 Parsed:\n```json\n$jsonOutput\n```');

    if (moduleResponse != null && moduleResponse.isNotEmpty) {
      buffer.write('\n🔧 $moduleResponse');
    }

    return buffer.toString();
  }

  Map<String, dynamic> _extractKeyValuePairs(String message) {
    final result = <String, dynamic>{};
    final tokens = _tokenize(message);

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
          result[key] = _parseValue(valueParts.join(' '));
        }
      } else {
        i++;
      }
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

    // ✅ Fixed variable name
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
