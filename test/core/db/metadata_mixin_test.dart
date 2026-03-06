import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/core/db/metadata_mixin.dart';

class TestService with MetadataMixin {
  @override
  final MetadataService metadataService;
  TestService(this.metadataService);
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('MetadataMixin Splitting Logic', () {
    late DatabaseManager dbManager;
    late TestService testService;

    setUp(() async {
      dbManager = DatabaseManager(dbPathOverride: ':memory:');
      final meta = MetadataService(dbManager: dbManager);
      testService = TestService(meta);

      final db = await dbManager.database;
      await meta.initializeTables(db);
      await db.execute(
        'CREATE TABLE dummy (id INTEGER PRIMARY KEY AUTOINCREMENT, start_time TEXT, end_time TEXT, notes TEXT)',
      );
      await db.execute(
        'CREATE TABLE dummy_tags (dummy_id INTEGER, tag_id INTEGER)',
      );
    });

    test(
      'saveSplittableEntity should create multiple entries for multi-day sessions',
      () async {
        final db = await dbManager.database;

        // Session starts Friday 10 PM and ends Saturday 2 AM
        final start = DateTime(2026, 3, 6, 22, 0);
        final end = DateTime(2026, 3, 7, 2, 0);

        await testService.saveSplittableEntity(
          db: db,
          tableName: 'dummy',
          tagJunctionTable: 'dummy_tags',
          idColumn: 'dummy_id',
          baseData: {'notes': 'Split test'},
          start: start,
          end: end,
          tags: ['split'],
          module: 'test',
        );

        final results = await db.query('dummy');
        // Should be 2 rows
        expect(results.length, 2);

        // First row should end at 23:59:59
        expect(results[0]['end_time'].toString(), contains('23:59:59'));
        // Second row should start at 00:00:00
        expect(results[1]['start_time'].toString(), contains('00:00:00'));
      },
    );
  });
}
