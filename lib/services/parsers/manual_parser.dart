import 'dart:core';

/// Dumb Strict Manual Parser with quoted value support
/// Rules:
/// - target_module is the token starting with @ (strip @)
/// - Only tokens starting with -- are keys
/// - Value is the next token after the key, or null if missing
/// - If value is quoted ("") spaces inside are PRESERVED as a single value
/// - Special handling: tags always become a list, even single element
/// - Adds timestamp and day_of_week
class ManualParser {
  Map<String, dynamic> parse(
    String message,
    DateTime timestamp,
    String dayOfWeek,
  ) {
    // 1️⃣ Tokenize using the improved regex to keep quotes intact
    final tokens = _tokenize(message);
    if (tokens.isEmpty) return {};

    final result = <String, dynamic>{};

    // 2️⃣ Extract target_module (@module)
    final targetIndex = tokens.indexWhere((t) => t.startsWith('@'));
    if (targetIndex != -1) {
      result['target_module'] = tokens[targetIndex].substring(1); // strip @
      tokens.removeAt(targetIndex);
    } else {
      result['target_module'] = 'chat'; // default fallback
    }

    // 3️⃣ Parse flags (--key value)
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (token.startsWith('--')) {
        final key = token.substring(2);
        String? value;

        // Check if the next token exists and is NOT another flag
        if (i + 1 < tokens.length && !tokens[i + 1].startsWith('--')) {
          value = tokens[i + 1];
          i++; // Consume the value token so it's not treated as a key

          // 4️⃣ Remove surrounding quotes but KEEP internal spaces
          if (value.length >= 2 &&
              value.startsWith('"') &&
              value.endsWith('"')) {
            value = value.substring(1, value.length - 1);
          }
        }

        // 5️⃣ Special handling for tags (comma-separated string to List)
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
          // Note: spaces are preserved here because 'value' came from
          // a single regex match group.
          result[key] = value;
        }
      }
    }

    // 6️⃣ Metadata
    result['timestamp'] = timestamp.toIso8601String();
    result['day_of_week'] = dayOfWeek;

    return result;
  }

  /// Tokenizes message:
  /// Group 1: Matches anything inside double quotes (including spaces)
  /// Group 2: Matches any non-whitespace sequence (flags or simple words)
  List<String> _tokenize(String message) {
    // This regex ensures "quoted strings" are treated as one token
    final regex = RegExp(r'("[^"]*"|\S+)');
    final tokens = <String>[];

    for (final match in regex.allMatches(message)) {
      tokens.add(match.group(0)!);
    }
    return tokens;
  }
}

void main() {
  final parser = ManualParser();

  // Test Case 1: Quoted note with spaces
  final msg1 =
      '@time --action start --note "working on maths in anki" --tags maths,anki';
  final parsed1 = parser.parse(msg1, DateTime.now(), 'Sunday');
  print('--- Test 1 (Quoted Note) ---');
  print(parsed1);

  // Test Case 2: Missing value for note
  final msg2 = '@time --action start --note --tags maths';
  final parsed2 = parser.parse(msg2, DateTime.now(), 'Sunday');
  print('\n--- Test 2 (Empty Note) ---');
  print(parsed2);

  // Test Case 3: Tags with spaces
  final msg3 = '@time --tags "maths, study session"';
  final parsed3 = parser.parse(msg3, DateTime.now(), 'Sunday');
  print('\n--- Test 3 (Quoted Tags) ---');
  print(parsed3);
}
