import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Metadata Service Duplication Logic', () {
    late DatabaseManager dbManager;
    late MetadataService metadata;
    late Database db;

    setUp(() async {
      dbManager = DatabaseManager(dbPathOverride: ':memory:');
      metadata = MetadataService(dbManager: dbManager);
      db = await dbManager.database;
      await metadata.initializeTables(db);
    });

    test('should allow same tag name in DIFFERENT modules', () async {
      await metadata.ensureTagExists(db, 'focus', module: 'time');
      await metadata.ensureTagExists(db, 'focus', module: 'sleep');

      final tags = await metadata.getAllTags();
      // Should have 2 distinct entries because of the UNIQUE(name, module) constraint
      expect(tags.length, 2);
    });

    test('should NOT duplicate same tag in SAME module', () async {
      await metadata.ensureTagExists(db, 'HEALTH', module: 'global');
      await metadata.ensureTagExists(db, ' health ', module: 'global');

      final tags = await metadata.getAllTags(module: 'global');
      expect(tags.length, 1);
      expect(tags.first['name'], 'health');
    });
  });
}
