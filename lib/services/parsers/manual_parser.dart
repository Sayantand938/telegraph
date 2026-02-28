// lib/services/parsers/manual_parser.dart
import 'dart:core';

/// Dumb Strict Manual Parser with quoted value support
class ManualParser {
  Map<String, dynamic> parse(
    String message,
    DateTime timestamp,
    String dayOfWeek,
  ) {
    final tokens = _tokenize(message);
    if (tokens.isEmpty) return {};

    final result = <String, dynamic>{};

    // Extract target_module (@module)
    final targetIndex = tokens.indexWhere((t) => t.startsWith('@'));
    if (targetIndex != -1) {
      result['target_module'] = tokens[targetIndex].substring(1);
      tokens.removeAt(targetIndex);
    } else {
      result['target_module'] = 'chat';
    }

    // Parse flags (--key value)
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.startsWith('--')) {
        final key = token.substring(2);
        String? value;

        if (i + 1 < tokens.length && !tokens[i + 1].startsWith('--')) {
          value = tokens[i + 1];
          i++;
          if (value.length >= 2 &&
              value.startsWith('"') &&
              value.endsWith('"')) {
            value = value.substring(1, value.length - 1);
          }
        }

        if (key.toLowerCase() == 'tags') {
          if (value == null || value.trim().isEmpty) {
            result[key] = <String>[];
          } else {
            result[key] = value
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();
          }
        } else {
          result[key] = value;
        }
      }
    }

    result['timestamp'] = timestamp.toIso8601String();
    result['day_of_week'] = dayOfWeek;
    return result;
  }

  List<String> _tokenize(String message) {
    final regex = RegExp(r'("[^"]*"|\S+)');
    final tokens = <String>[];
    for (final match in regex.allMatches(message)) {
      tokens.add(match.group(0)!);
    }
    return tokens;
  }
}
