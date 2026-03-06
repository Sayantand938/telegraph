import 'package:sqflite/sqflite.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/core/utils/datetime_logic.dart';

mixin MetadataMixin {
  MetadataService get metadataService;

  /// Handles multi-day splitting and junction linking for ANY module.
  Future<void> saveSplittableEntity({
    required DatabaseExecutor db,
    required String tableName,
    required String tagJunctionTable,
    required String idColumn,
    required Map<String, dynamic> baseData,
    required DateTime start,
    required DateTime end,
    required List<String> tags,
    String? participantJunctionTable,
    List<String>? participants,
    required String module,
  }) async {
    final segments = DateTimeLogic.splitAcrossDays(start, end);

    for (final segment in segments) {
      final Map<String, dynamic> data = Map.from(baseData);
      data['start_time'] = segment.start.toIso8601String();
      data['end_time'] = segment.end.toIso8601String();

      final id = await db.insert(tableName, data);

      // Link Tags
      await metadataService.linkEntityToTags(
        db,
        tagJunctionTable,
        idColumn,
        id,
        tags,
        module: module,
      );

      // Link Participants (if applicable to the module)
      if (participantJunctionTable != null &&
          participants != null &&
          participants.isNotEmpty) {
        await metadataService.linkEntityToParticipants(
          db,
          participantJunctionTable,
          idColumn,
          id,
          participants,
          module: module,
        );
      }
    }
  }
}
