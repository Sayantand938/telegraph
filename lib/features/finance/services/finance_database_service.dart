import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/core/db/metadata_mixin.dart';
import 'package:telegraph/features/finance/models/transaction_model.dart';

class FinanceDatabaseService with MetadataMixin {
  final DatabaseManager _dbManager;
  @override
  final MetadataService metadataService;

  FinanceDatabaseService({
    required DatabaseManager dbManager,
    required this.metadataService,
  }) : _dbManager = dbManager;

  static const tableFinance = 'finance_transactions';
  static const tableJunctionTags = 'finance_transaction_tags';
  static const tableJunctionParts = 'finance_transaction_participants';

  Future<void> recordTransaction({
    required double amount,
    required String type,
    required DateTime date,
    required String notes,
    required List<String> tags,
    required List<String> participants,
  }) async {
    final db = await _dbManager.database;
    await db.transaction((txn) async {
      final id = await txn.insert(tableFinance, {
        'amount': amount,
        'type': type,
        'transaction_date': date.toIso8601String(),
        'notes': notes,
      });

      await metadataService.linkEntityToTags(
        txn,
        tableJunctionTags,
        'transaction_id',
        id,
        tags,
        module: 'finance',
      );
      await metadataService.linkEntityToParticipants(
        txn,
        tableJunctionParts,
        'transaction_id',
        id,
        participants,
        module: 'finance',
      );
    });
  }

  Future<List<TransactionModel>> getTransactionsByDate(DateTime date) async {
    final db = await _dbManager.database;
    final dateStr = date.toIso8601String().split('T')[0];

    final res = await db.rawQuery(
      '''
      SELECT f.*,
        (SELECT GROUP_CONCAT(tg.name, ' ') FROM ${MetadataService.tableTags} tg
         JOIN $tableJunctionTags tj ON tg.id = tj.tag_id WHERE tj.transaction_id = f.id) as tag_list,
        (SELECT GROUP_CONCAT(p.name, ' ') FROM ${MetadataService.tableParticipants} p
         JOIN $tableJunctionParts pj ON p.id = pj.participant_id WHERE pj.transaction_id = f.id) as part_list
      FROM $tableFinance f
      WHERE DATE(f.transaction_date) = ?
      ORDER BY f.transaction_date ASC
    ''',
      [dateStr],
    );

    return res.map((map) {
      final tags =
          (map['tag_list'] as String?)
              ?.split(' ')
              .where((t) => t.isNotEmpty)
              .toList() ??
          [];
      final parts =
          (map['part_list'] as String?)
              ?.split(' ')
              .where((p) => p.isNotEmpty)
              .toList() ??
          [];
      return TransactionModel.fromMap(map, tags: tags, participants: parts);
    }).toList();
  }

  Future<int> deleteTransaction(int id) async {
    final db = await _dbManager.database;
    return await db.transaction((txn) async {
      await txn.delete(
        tableJunctionTags,
        where: 'transaction_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        tableJunctionParts,
        where: 'transaction_id = ?',
        whereArgs: [id],
      );
      return await txn.delete(tableFinance, where: 'id = ?', whereArgs: [id]);
    });
  }
}
