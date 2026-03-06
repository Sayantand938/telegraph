import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/engine/telegraph_engine.dart';
import 'package:telegraph/core/utils/response_codes.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Telegraph Sad Paths & Edge Cases', () {
    late TelegraphEngine engine;

    setUp(() async {
      engine = TelegraphEngine(dbPathOverride: ':memory:');
      await engine.initialize();
    });

    tearDown(() async => await engine.dispose());

    Future<String> handle(String input) =>
        engine.commandService.handleCommand(input);

    group('Parser & Global Sad Paths', () {
      test(
        'should return aggregated help for empty or whitespace input',
        () async {
          final res = await handle('   ');
          expect(res, contains('🤖 **Alison CLI**'));
          expect(res, contains('Time Tracking'));
          expect(res, contains('Sleep Tracking'));
        },
      );

      test('should return help for unknown module', () async {
        final res = await handle('weather get');
        expect(res, contains('🤖 **Alison CLI**'));
      });
    });

    group('Time Module Sad Paths', () {
      test('Double Start: should not allow starting two sessions', () async {
        await handle('time start "Session 1"');
        final res = await handle('time start "Session 2"');
        expect(res, contains('Already active'));
        expect(res, contains(ErrorCode.alreadyActive.code));
      });

      test('Ghost Stop: should handle stop when no session exists', () async {
        final res = await handle('time stop');
        expect(res, contains('No active session'));
        expect(res, contains(ErrorCode.noActiveSession.code));
      });

      test('Invalid Time Range: malformed strings', () async {
        final badRes = await handle('time log 99:99-88:88 "Garbage"');
        expect(badRes, contains('Invalid range'));
      });
    });

    group('Finance Module Sad Paths', () {
      test('Zero Amount: should reject zero or negative amounts', () async {
        final zero = await handle('finance log expense 0 "Nothing"');
        expect(zero, contains('Amount must be positive'));
      });

      test('Invalid Type: should only allow income/expense', () async {
        final res = await handle('finance log investment 100 "Profit"');
        expect(res, contains("Type must be 'income' or 'expense'"));
      });
    });

    group('Task & Meeting Sad Paths', () {
      test('Task Idempotency: completing non-existent task', () async {
        final res = await handle('task done 404');
        expect(res, contains('Not found'));
      });

      test('Meeting Overlap: should not allow concurrent meetings', () async {
        await handle('meeting start "Meeting 1"');
        final res = await handle('meeting start "Meeting 2"');
        expect(res, contains('Meeting already running'));
      });
    });

    group('Sleep Module Sad Paths', () {
      test(
        'Double Start: should not allow tracking two sleep sessions',
        () async {
          await handle('sleep start "Session 1"');
          final res = await handle('sleep start "Session 2"');
          expect(res, contains('Already tracking sleep'));
        },
      );

      test(
        'Ghost Stop: should handle stop when no sleep session exists',
        () async {
          final res = await handle('sleep stop');
          expect(res, contains('No active sleep session'));
        },
      );
    });
  });
}
