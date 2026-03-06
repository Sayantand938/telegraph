// lib/features/finance/finance_module.dart
import 'package:telegraph/core/module_interface.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/finance/services/finance_command_handler.dart';

class FinanceModule implements TelegraphModule {
  final FinanceCommandHandler _handler;

  FinanceModule(this._handler);

  @override
  String get name => "Finance Tracker";

  @override
  FeatureCommandHandler get handler => _handler;

  @override
  List<String> get onCreateSql => [
    '''CREATE TABLE IF NOT EXISTS finance_transactions (
id INTEGER PRIMARY KEY AUTOINCREMENT,
amount REAL NOT NULL,
type TEXT CHECK(type IN ('income', 'expense')) NOT NULL,
transaction_date TEXT NOT NULL,
notes TEXT
)''',
    '''CREATE INDEX IF NOT EXISTS idx_finance_date ON finance_transactions(transaction_date)''',
    '''CREATE INDEX IF NOT EXISTS idx_finance_type ON finance_transactions(type)''',
    '''CREATE TABLE IF NOT EXISTS finance_transaction_tags (
transaction_id INTEGER, tag_id INTEGER,
PRIMARY KEY(transaction_id, tag_id),
FOREIGN KEY(transaction_id) REFERENCES finance_transactions(id),
FOREIGN KEY(tag_id) REFERENCES ${MetadataService.tableTags}(id)
)''',
    '''CREATE TABLE IF NOT EXISTS finance_transaction_participants (
transaction_id INTEGER, participant_id INTEGER,
PRIMARY KEY(transaction_id, participant_id),
FOREIGN KEY(transaction_id) REFERENCES finance_transactions(id),
FOREIGN KEY(participant_id) REFERENCES ${MetadataService.tableParticipants}(id)
)''',
  ];

  @override
  bool get isEnabled => true;

  @override
  int get version => 1;
}
