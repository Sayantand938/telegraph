import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/db/database_manager.dart';

void main() {
  // Initialize FFI for unit tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseManager', () {
    late DatabaseManager dbManager;

    setUp(() {
      dbManager = DatabaseManager(dbPathOverride: ':memory:');
    });

    tearDown(() async {
      await dbManager.close();
    });

    test('should initialize and create tables', () async {
      // ✅ Added IF NOT EXISTS for robustness
      const script =
          'CREATE TABLE IF NOT EXISTS test_table (id INTEGER PRIMARY KEY)';
      await dbManager.initialize([script]);

      final db = await dbManager.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='test_table'",
      );

      expect(result.isNotEmpty, isTrue);
      expect(dbManager.isReady, isTrue);
    });

    test('should enable foreign keys by default', () async {
      await dbManager.initialize([]);
      final db = await dbManager.database;

      final result = await db.rawQuery('PRAGMA foreign_keys');
      expect(result.first['foreign_keys'], 1);
    });
  });
}
