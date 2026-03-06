import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/finance/services/finance_database_service.dart';
import 'package:telegraph/features/finance/services/finance_command_handler.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('FinanceCommandHandler Extensive', () {
    late DatabaseManager dbManager;
    late FinanceDatabaseService dbService;
    late FinanceCommandHandler handler;
    final fixedTime = DateTime(2026, 3, 6, 12, 0); // Friday

    setUp(() async {
      dbManager = DatabaseManager(dbPathOverride: ':memory:');
      final metadata = MetadataService(dbManager: dbManager);
      final db = await dbManager.database;
      await metadata.initializeTables(db);

      await db.execute(
        'CREATE TABLE finance_transactions (id INTEGER PRIMARY KEY, amount REAL, type TEXT, transaction_date TEXT, notes TEXT)',
      );
      await db.execute(
        'CREATE TABLE finance_transaction_tags (transaction_id INTEGER, tag_id INTEGER)',
      );
      await db.execute(
        'CREATE TABLE finance_transaction_participants (transaction_id INTEGER, participant_id INTEGER)',
      );

      dbService = FinanceDatabaseService(
        dbManager: dbManager,
        metadataService: metadata,
      );
      handler = FinanceCommandHandler(dbService, clock: () => fixedTime);
    });

    tearDown(() async => await dbManager.close());

    test(
      'should handle "finance log" with relative date "yesterday"',
      () async {
        final response = await handler.handle(
          'finance log expense 45.00 yesterday "Dinner" #food',
        );

        expect(response, contains('✅ **Logged**'));
        expect(response, contains('"amount": 45.0'));

        // Verify DB entry for March 5th
        final txs = await dbService.getTransactionsByDate(DateTime(2026, 3, 5));
        expect(txs.length, 1);
        expect(txs.first.notes, "Dinner");
      },
    );

    test('should correctly calculate Net Balance in summary', () async {
      await handler.handle('finance log income 1000 today "Freelance"');
      await handler.handle('finance log expense 250 today "Groceries"');

      final response = await handler.handle('finance summary');

      expect(response, contains('📊 **Finance Report**'));
      expect(response, contains('"income": "+₹1000.00"'));
      expect(response, contains('"expense": "-₹250.00"'));
      expect(response, contains('"net": "₹750.00"'));
    });

    test('should reject negative amounts', () async {
      final response = await handler.handle(
        'finance log expense -50 "Invalid"',
      );
      expect(response, contains('🚨 **Error**'));
      expect(response, contains('Amount must be positive'));
      expect(response, contains('"code": "FIN_ERR_001"'));
    });

    test('should reject invalid transaction types', () async {
      final response = await handler.handle(
        'finance log investment 100 "Stock"',
      );
      expect(response, contains('🚨 **Error**'));
      expect(response, contains("Type must be 'income' or 'expense'"));
    });

    test('should handle "finance log" with automatic today date', () async {
      // Skipping the date argument entirely
      final response = await handler.handle(
        'finance log expense 15.00 "Coffee" @friend #social',
      );

      expect(response, contains('✅ **Logged**'));
      expect(response, contains('"amount": 15.0'));
      expect(response, contains('friend'));
    });

    test('should handle complex notes and special characters', () async {
      final response = await handler.handle(
        'finance log expense 99.99 today "Shopping @ Mall (Sales!)" #fun',
      );

      expect(response, contains('✅ **Logged**'));
      expect(response, contains('Shopping @ Mall (Sales!)'));
    });

    test('should delete transaction correctly', () async {
      await handler.handle('finance log income 50 today "Gift"');
      final response = await handler.handle('finance delete 1');

      expect(response, contains('✅ **Deleted**'));
      expect(response, contains('"id": 1'));

      final txs = await dbService.getTransactionsByDate(fixedTime);
      expect(txs, isEmpty);
    });
  });
}
