import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/engine/telegraph_engine.dart';
import 'package:telegraph/features/chat/models/message_model.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Chat History Stress', () {
    late TelegraphEngine engine;

    setUp(() async {
      engine = TelegraphEngine(dbPathOverride: ':memory:');
      await engine.initialize();
    });

    test('should save and retrieve 100 messages sequentially', () async {
      for (int i = 0; i < 100; i++) {
        await engine.saveMessageToHistory(
          MessageModel(text: 'Message $i', isMe: i % 2 == 0),
        );
      }

      final history = await engine.loadChatHistory();
      expect(history.length, 100);
      expect(history.first.text, 'Message 0');
      expect(history.last.text, 'Message 99');
    });

    test(
      'should handle extremely long single messages (5000+ characters)',
      () async {
        final longText = 'A' * 5000;
        await engine.saveMessageToHistory(
          MessageModel(text: longText, isMe: true),
        );

        final history = await engine.loadChatHistory();
        expect(history.last.text.length, 5000);
      },
    );
  });
}
