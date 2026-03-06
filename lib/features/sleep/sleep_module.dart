import 'package:telegraph/core/module_interface.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/sleep/services/sleep_command_handler.dart';

class SleepModule implements TelegraphModule {
  final SleepCommandHandler _handler;

  SleepModule(this._handler);

  @override
  String get name => "Sleep Tracker";

  @override
  FeatureCommandHandler get handler => _handler;

  @override
  List<String> get onCreateSql => [
    '''CREATE TABLE IF NOT EXISTS sleep_sessions (
id INTEGER PRIMARY KEY AUTOINCREMENT,
start_time TEXT NOT NULL,
end_time TEXT,
notes TEXT
)''',
    '''CREATE INDEX IF NOT EXISTS idx_sleep_start ON sleep_sessions(start_time)''',
    '''CREATE INDEX IF NOT EXISTS idx_sleep_end ON sleep_sessions(end_time)''',
    '''CREATE TABLE IF NOT EXISTS sleep_session_tags (
sleep_id INTEGER, tag_id INTEGER,
PRIMARY KEY(sleep_id, tag_id),
FOREIGN KEY(sleep_id) REFERENCES sleep_sessions(id),
FOREIGN KEY(tag_id) REFERENCES ${MetadataService.tableTags}(id)
)''',
  ];

  @override
  bool get isEnabled => true;

  @override
  int get version => 1;
}
