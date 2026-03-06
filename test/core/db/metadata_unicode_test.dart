import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Metadata Unicode & Script Safety', () {
    late DatabaseManager dbManager;
    late MetadataService metadata;
    late Database db;

    setUp(() async {
      dbManager = DatabaseManager(dbPathOverride: ':memory:');
      metadata = MetadataService(dbManager: dbManager);
      db = await dbManager.database;
      await metadata.initializeTables(db);
    });

    test('should support Multi-language Tags (Kanji, Cyrillic)', () async {
      const jpTag = '仕事'; // "Work" in Japanese
      const ruTag = 'важный'; // "Important" in Russian

      final id1 = await metadata.ensureTagExists(db, jpTag);
      final id2 = await metadata.ensureTagExists(db, ruTag);

      expect(id1, isNotNull);
      expect(id2, isNotNull);

      final tags = await metadata.getAllTags();
      expect(tags.any((t) => t['name'] == '仕事'), isTrue);
      expect(tags.any((t) => t['name'] == 'важный'), isTrue);
    });

    test('should handle symbols in participant names safely', () async {
      const complexPart = 'D.O.R.K.S (Team-A)';
      final id = await metadata.ensureParticipantExists(db, complexPart);

      expect(id, isNotNull);
      final parts = await metadata.getAllParticipants();
      // Parser/Metadata usually lowers case: d.o.r.k.s (team-a)
      expect(parts.first['name'], complexPart.toLowerCase());
    });
  });
}
