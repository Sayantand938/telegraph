import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/engine/telegraph_engine.dart';
import 'package:telegraph/features/chat/models/message_model.dart';
import 'package:telegraph/core/utils/logger.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Alison Happy Path - A Day in the Life', () {
    late TelegraphEngine engine;

    setUp(() async {
      engine = TelegraphEngine(dbPathOverride: ':memory:');
      await engine.initialize();
    });

    tearDown(() async {
      await engine.dispose();
    });

    // Helper to mimic ChatController
    Future<String> sendCommand(String input) async {
      await engine.saveMessageToHistory(MessageModel(text: input, isMe: true));
      final response = await engine.commandService.handleCommand(input);
      await engine.saveMessageToHistory(
        MessageModel(text: response, isMe: false),
      );
      return response;
    }

    test('Full User Journey: Morning to Evening with Sleep', () async {
      Logger.log('\n--- 🌅 Morning: Logging Work ---');

      // 1. Log work for yesterday to avoid "future time" clipping
      final logRes = await sendCommand(
        'time log yesterday 08:00-12:00 "Developing Alison UI" #work #flutter',
      );
      expect(logRes, contains('TIME_003'));

      Logger.log('--- 🤝 Mid-Day: Team Meeting ---');

      // 2. Log a meeting for yesterday
      final meetRes = await sendCommand(
        'meeting log yesterday 12:00-13:00 "Sprint Planning" @bob @alice #agile',
      );
      expect(meetRes, contains('MEET_003'));

      Logger.log('--- 🥗 Lunch: Logging Expense ---');

      // 3. Log an expense
      final finRes = await sendCommand(
        'finance log expense 15.50 yesterday "Healthy Salad" #food',
      );
      expect(finRes, contains('FIN_001'));

      Logger.log('--- 📝 Afternoon: Tasks ---');

      // 4. Add task
      await sendCommand('task add "Update Documentation" #docs');

      // 5. List tasks
      final listRes = await sendCommand('task list');
      expect(listRes, contains('Update Documentation'));

      // 6. Complete task
      final doneRes = await sendCommand('task done 1');
      expect(doneRes, contains('TASK_002'));

      Logger.log('--- 🌇 Evening: Reviewing Progress ---');

      // 7. Check Summary for yesterday
      final summaryRes = await sendCommand('time summary yesterday');
      expect(summaryRes, contains('📊 **Summary Report**'));

      Logger.log('--- 🌙 Night: Sleep Tracking ---');

      // 8. Start sleep tracking (simulated)
      await sendCommand('sleep start "Long day" #tired');

      // 9. Log a full night of sleep for yesterday
      // Using 00:00-08:00 yesterday ensures exactly 8h duration
      final sleepLogRes = await sendCommand(
        'sleep log yesterday 00:00-08:00 "Full night rest" #good #recovery',
      );
      expect(sleepLogRes, contains('✅ **Sleep Logged**'));
      expect(sleepLogRes, contains('"duration": "8h 0m"'));

      // 10. Check sleep summary for yesterday
      final sleepSummary = await sendCommand('sleep summary yesterday');
      expect(sleepSummary, contains('📊 **Sleep Report**'));
      expect(sleepSummary, contains('"total_sleep": "8h 0m"'));

      // Verify message history: 10 commands sent, 10 responses = 20 messages
      final history = await engine.loadChatHistory();
      expect(history.length, equals(20));

      Logger.log('--- ✅ Happy Path Complete: All modules verified ---');
    });
  });
}
