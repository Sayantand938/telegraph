import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart'; // Needed for Sqflite.firstIntValue
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/finance/services/finance_database_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi; // Fixed typo here

  group('FinanceDatabaseService Extensive', () {
    late DatabaseManager dbManager;
    late MetadataService metadataService;
    late FinanceDatabaseService financeDb;

    setUp(() async {
      dbManager = DatabaseManager(dbPathOverride: ':memory:');
      metadataService = MetadataService(dbManager: dbManager);
      final db = await dbManager.database;
      await metadataService.initializeTables(db);

      await db.execute('''CREATE TABLE finance_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type TEXT CHECK(type IN ('income', 'expense')) NOT NULL,
        transaction_date TEXT NOT NULL,
        notes TEXT
      )''');
      await db.execute('''CREATE TABLE finance_transaction_tags (
        transaction_id INTEGER, tag_id INTEGER,
        PRIMARY KEY(transaction_id, tag_id),
        FOREIGN KEY(transaction_id) REFERENCES finance_transactions(id),
        FOREIGN KEY(tag_id) REFERENCES tags(id)
      )''');
      await db.execute('''CREATE TABLE finance_transaction_participants (
        transaction_id INTEGER, participant_id INTEGER,
        PRIMARY KEY(transaction_id, participant_id),
        FOREIGN KEY(transaction_id) REFERENCES finance_transactions(id),
        FOREIGN KEY(participant_id) REFERENCES participants(id)
      )''');

      financeDb = FinanceDatabaseService(
        dbManager: dbManager,
        metadataService: metadataService,
      );
    });

    tearDown(() async => await dbManager.close());

    test('should link and retrieve multiple tags and participants', () async {
      final date = DateTime(2026, 3, 6);
      await financeDb.recordTransaction(
        amount: 250.0,
        type: 'expense',
        date: date,
        notes: 'Team Lunch',
        tags: ['food', 'work'],
        participants: ['alice', 'bob'],
      );

      final results = await financeDb.getTransactionsByDate(date);
      expect(results.length, 1);

      final tx = results.first;
      expect(tx.displayTags, containsAll(['#food', '#work']));
      expect(tx.displayParticipants, containsAll(['@alice', '@bob']));
    });

    test('should ensure unique metadata entries in global tables', () async {
      final date = DateTime(2026, 3, 6);

      // Record two different transactions with the same tag
      await financeDb.recordTransaction(
        amount: 10.0,
        type: 'expense',
        date: date,
        notes: 'A',
        tags: ['shared'],
        participants: [],
      );
      await financeDb.recordTransaction(
        amount: 20.0,
        type: 'expense',
        date: date,
        notes: 'B',
        tags: ['shared'],
        participants: [],
      );

      final db = await dbManager.database;
      final tagCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM tags WHERE name = ?', [
          'shared',
        ]),
      );

      // The tag "shared" should only exist ONCE in the tags table
      expect(tagCount, 1);
    });

    test('should delete transaction and cleanup junction tables', () async {
      await financeDb.recordTransaction(
        amount: 100.0,
        type: 'income',
        date: DateTime(2026, 3, 6),
        notes: 'Bonus',
        tags: ['work'],
        participants: [],
      );

      final txs = await financeDb.getTransactionsByDate(DateTime(2026, 3, 6));
      final id = txs.first.id!;

      await financeDb.deleteTransaction(id);

      final db = await dbManager.database;
      final junctionCheck = await db.query(
        'finance_transaction_tags',
        where: 'transaction_id = ?',
        whereArgs: [id],
      );

      expect(junctionCheck, isEmpty);
    });
  });
}
