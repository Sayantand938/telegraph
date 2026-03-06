import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/finance/services/finance_database_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Finance Database Precision', () {
    late DatabaseManager dbManager;
    late FinanceDatabaseService financeDb;

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

      financeDb = FinanceDatabaseService(
        dbManager: dbManager,
        metadataService: metadata,
      );
    });

    test('should handle extremely large amounts (Trillions)', () async {
      const hugeAmount = 1000000000000.0;
      await financeDb.recordTransaction(
        amount: hugeAmount,
        type: 'income',
        date: DateTime.now(),
        notes: 'Wealthy Boss',
        tags: [],
        participants: [],
      );

      final results = await financeDb.getTransactionsByDate(DateTime.now());
      expect(results.first.amount, hugeAmount);
    });

    test('should handle SQL characters in notes safely', () async {
      const maliciousNote = "Value'); DROP TABLE finance_transactions; --";
      await financeDb.recordTransaction(
        amount: 10.0,
        type: 'expense',
        date: DateTime.now(),
        notes: maliciousNote,
        tags: [],
        participants: [],
      );

      final results = await financeDb.getTransactionsByDate(DateTime.now());
      expect(results.first.notes, maliciousNote);
      // If the code is safe, the next line won't crash
      expect(results.isNotEmpty, isTrue);
    });
  });
}
