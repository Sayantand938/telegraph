import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/engine/telegraph_engine.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TelegraphEngine Maintenance', () {
    late TelegraphEngine engine;

    setUp(() async {
      engine = TelegraphEngine(dbPathOverride: ':memory:');
      await engine.initialize();
    });

    test(
      'should delete chat history from previous days during maintenance',
      () async {
        final db = await engine.dbManager.database;

        // 1. Insert a message from "Yesterday"
        final yesterday = DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String();
        await db.insert('chat_history', {
          'text': 'Stale Message',
          'is_me': 1,
          'timestamp': yesterday,
        });

        // 2. Insert a message from "Today"
        await db.insert('chat_history', {
          'text': 'Fresh Message',
          'is_me': 1,
          'timestamp': DateTime.now().toIso8601String(),
        });

        // 3. Trigger Maintenance
        await engine.runMaintenance();

        // 4. Verify results
        final history = await engine.loadChatHistory();

        expect(history.any((m) => m.text == 'Fresh Message'), isTrue);
        expect(history.any((m) => m.text == 'Stale Message'), isFalse);
      },
    );
  });
}
