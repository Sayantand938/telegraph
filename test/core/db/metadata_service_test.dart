import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';

void main() {
  // Initialize FFI for unit tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('MetadataService', () {
    late DatabaseManager dbManager;
    late MetadataService metadataService;
    late Database db;

    setUp(() async {
      dbManager = DatabaseManager(dbPathOverride: ':memory:');
      metadataService = MetadataService(dbManager: dbManager);
      db = await dbManager.database;
      await metadataService.initializeTables(db);
    });

    tearDown(() async {
      await dbManager.close();
    });

    test('ensureTagExists should be case-insensitive and unique', () async {
      final id1 = await metadataService.ensureTagExists(db, 'Flutter');
      final id2 = await metadataService.ensureTagExists(db, ' flutter ');

      expect(id1, isNotNull);
      expect(id1, id2);

      final tags = await metadataService.getAllTags();
      expect(tags.length, 1);
      expect(tags.first['name'], 'flutter');
    });

    test('ensureParticipantExists should store module scope', () async {
      final id = await metadataService.ensureParticipantExists(
        db,
        'Alice',
        module: 'work',
      );

      // ✅ Used the id variable to satisfy the linter and verify correctness
      expect(id, isNotNull);
      expect(id! > 0, isTrue);

      final participants = await metadataService.getAllParticipants(
        module: 'work',
      );
      expect(participants.length, 1);
      expect(participants.first['name'], 'alice');
      expect(participants.first['module'], 'work');
    });

    test('linkEntityToTags should handle junction table inserts', () async {
      // Create a dummy table to link to
      await db.execute('CREATE TABLE dummy (id INTEGER PRIMARY KEY)');
      await db.execute(
        'CREATE TABLE dummy_tags (dummy_id INTEGER, tag_id INTEGER)',
      );
      await db.insert('dummy', {'id': 1});

      await metadataService.linkEntityToTags(db, 'dummy_tags', 'dummy_id', 1, [
        'tagA',
        'tagB',
      ]);

      final result = await db.query('dummy_tags');
      expect(result.length, 2);
    });
  });
}
