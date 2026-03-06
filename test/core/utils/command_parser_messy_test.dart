import 'package:flutter_test/flutter_test.dart';
import 'package:telegraph/core/utils/command_parser.dart';

void main() {
  group('CommandParser Messy Inputs', () {
    test('Emoji in notes and tags', () {
      final cmd = ParsedCommand.parse('task add "Buy 🍎 for 🥧" #grocery_🔥');
      expect(cmd.notes, 'Buy 🍎 for 🥧');
      // Case-insensitivity turns 🔥 into 🔥 (no change)
      expect(cmd.tags, contains('grocery_🔥'));
    });

    test('Duplicate tags should be extracted as list', () {
      final cmd = ParsedCommand.parse('time log 1h #work #work #WORK');
      expect(cmd.tags.length, 3);
      expect(cmd.tags.toSet().length, 1); // unique check
    });

    test('Handling weird metadata formats', () {
      final cmd = ParsedCommand.parse('sleep start #loc:bedroom #temp:68f');
      expect(cmd.tags, contains('loc:bedroom'));
      expect(cmd.tags, contains('temp:68f'));
    });

    test('Unbalanced quotes safety', () {
      // Logic: If quotes don't match, notes are usually empty or everything is remainder
      final cmd = ParsedCommand.parse('task add "Broken quote');
      expect(cmd.module, 'task');
      expect(cmd.action, 'add');
    });
  });
}
