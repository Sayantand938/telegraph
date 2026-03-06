import 'package:flutter_test/flutter_test.dart';
import 'package:telegraph/core/utils/command_parser.dart';

void main() {
  group('CommandParser Edge Cases', () {
    final now = DateTime(2026, 3, 7, 12, 0);

    test('should handle quoted notes with special characters', () {
      final cmd = ParsedCommand.parse(
        'time log "Coding @ midnight! (test)" #work',
        clock: () => now,
      );
      expect(cmd.notes, 'Coding @ midnight! (test)');
      expect(cmd.tags, contains('work'));
    });

    test('should parse complex duration formats', () {
      final cmd = ParsedCommand.parse(
        'sleep log 1.5h "Short nap"',
        clock: () => now,
      );
      expect(cmd.duration?.inMinutes, 90);
      expect(cmd.notes, 'Short nap');
    });

    test('should handle multiple tags and participants mixed', () {
      final cmd = ParsedCommand.parse(
        'meeting start "Sync" #urgent @boss #project_alison @dev_team',
      );
      expect(cmd.tags, containsAll(['urgent', 'project_alison']));
      expect(cmd.participants, containsAll(['boss', 'dev_team']));
    });

    test('should identify modules correctly regardless of case', () {
      expect(ParsedCommand.parse('SLEEP status').module, 'sleep');
      expect(ParsedCommand.parse('fInAnCe summary').module, 'finance');
    });

    test('should return empty module for unknown commands', () {
      final cmd = ParsedCommand.parse('weather check "london"');
      expect(cmd.module, isEmpty);
    });

    test('should handle "last [day]" consolidation', () {
      final cmd = ParsedCommand.parse(
        'time summary last friday',
        clock: () => now,
      );
      // Verify "last" and "friday" were joined into args[0]
      expect(cmd.args[0], 'last friday');
    });
  });
}
