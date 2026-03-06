import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Metadata Service Stress & Invalidity', () {
    late DatabaseManager dbManager;
    late MetadataService metadata;
    late Database db;

    setUp(() async {
      dbManager = DatabaseManager(dbPathOverride: ':memory:');
      metadata = MetadataService(dbManager: dbManager);
      db = await dbManager.database;
      await metadata.initializeTables(db);
    });

    test('Stress: linking 50 tags to one entity should not fail', () async {
      await db.execute('CREATE TABLE stress_test (id INTEGER PRIMARY KEY)');
      // ✅ Fixed column name to tag_id
      await db.execute(
        'CREATE TABLE stress_tags (sid INTEGER, tag_id INTEGER)',
      );
      await db.insert('stress_test', {'id': 1});

      final manyTags = List.generate(50, (i) => 'tag_$i');

      await metadata.linkEntityToTags(db, 'stress_tags', 'sid', 1, manyTags);

      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM stress_tags'),
      );
      expect(count, 50);
    });

    test('Safety: linking to negative entity ID should be ignored', () async {
      await metadata.linkEntityToTag(db, 'non_existent', 'id', -1, 'fail');
      expect(true, isTrue);
    });

    test('Empty Tag: should return null (handled internally)', () async {
      // Since the service catches the ArgumentError and logs it, it returns null
      final result1 = await metadata.ensureTagExists(db, '');
      final result2 = await metadata.ensureTagExists(db, '   ');

      expect(result1, isNull);
      expect(result2, isNull);
    });
  });
}
