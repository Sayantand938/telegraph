import 'dart:core';

/// Dumb Strict Manual Parser with quoted value support
/// Rules:
/// - target_module is the token starting with @ (strip @)
/// - Only tokens starting with -- are keys
/// - Value is the next token after the key, or null if missing
/// - If value is quoted ("") allow spaces inside
/// - Special handling: tags always become a list, even single element
/// - Adds timestamp and day_of_week
class ManualParser {
  Map<String, dynamic> parse(
    String message,
    DateTime timestamp,
    String dayOfWeek,
  ) {
    final tokens = _tokenize(message);
    if (tokens.isEmpty) return {};

    final result = <String, dynamic>{};

    // 1️⃣ Extract target_module
    final targetIndex = tokens.indexWhere((t) => t.startsWith('@'));
    if (targetIndex != -1) {
      result['target_module'] = tokens[targetIndex].substring(1); // strip @
      tokens.removeAt(targetIndex);
    } else {
      result['target_module'] = 'chat'; // default fallback
    }

    // 2️⃣ Parse flags only
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.startsWith('--')) {
        final key = token.substring(2);
        String? value;

        // take next token if exists and it's NOT a flag
        if (i + 1 < tokens.length && !tokens[i + 1].startsWith('--')) {
          value = tokens[i + 1];
          i++; // skip next token
        }

        // 3️⃣ Remove quotes if present
        if (value != null &&
            value.length >= 2 &&
            value.startsWith('"') &&
            value.endsWith('"')) {
          value = value.substring(1, value.length - 1);
        }

        // 4️⃣ Special handling for tags
        if (key.toLowerCase() == 'tags') {
          if (value == null || value.trim().isEmpty) {
            result[key] = <String>[]; // empty list
          } else {
            result[key] = value
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();
          }
        } else {
          result[key] = value; // null if missing
        }
      }
    }

    // 5️⃣ Envelope
    result['timestamp'] = timestamp.toIso8601String();
    result['day_of_week'] = dayOfWeek;

    return result;
  }

  /// Tokenizes message but keeps quoted strings together
  List<String> _tokenize(String message) {
    final regex = RegExp(r'"[^"]*"|\S+');
    final tokens = <String>[];
    for (final match in regex.allMatches(message)) {
      var token = match.group(0)!;
      tokens.add(token);
    }
    return tokens;
  }
}

/// Example usage
void main() {
  final parser = ManualParser();

  final msg1 =
      '@time --action start --note "I am working on project" --tags abc,xyz';
  final parsed1 = parser.parse(msg1, DateTime.now(), 'Monday');
  print(parsed1);

  final msg2 = '@time --action start --note --tags abc';
  final parsed2 = parser.parse(msg2, DateTime.now(), 'Monday');
  print(parsed2);

  final msg3 = '@chat --verbose --tags';
  final parsed3 = parser.parse(msg3, DateTime.now(), 'Tuesday');
  print(parsed3);
}
