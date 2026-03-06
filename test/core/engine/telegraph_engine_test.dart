import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/engine/telegraph_engine.dart';
import 'package:telegraph/features/chat/models/message_model.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TelegraphEngine Daily Clean', () {
    late TelegraphEngine engine;

    setUp(() {
      engine = TelegraphEngine(dbPathOverride: ':memory:');
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('initialize should setup all core systems', () async {
      await engine.initialize();
      expect(engine.isReady, isTrue);
      // ✅ Fix: Updated to 5 modules (Time, Finance, Meeting, Task, Sleep)
      expect(engine.registeredModuleCount, 5);
    });

    test('chat history should save and load correctly', () async {
      await engine.initialize();

      final myMsg = MessageModel(text: 'Hello Engine', isMe: true);
      await engine.saveMessageToHistory(myMsg);

      final history = await engine.loadChatHistory();
      expect(history.length, 1);
      expect(history.first.text, 'Hello Engine');
      expect(history.first.isMe, isTrue);
    });
  });
}
