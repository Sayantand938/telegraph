// lib/features/time/time_module.dart
import 'package:telegraph/core/module_interface.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/time/services/time_command_handler.dart';

class TimeModule implements TelegraphModule {
  final TimeCommandHandler _handler;

  TimeModule(this._handler);

  @override
  String get name => "Time Tracker";

  @override
  FeatureCommandHandler get handler => _handler;

  @override
  List<String> get onCreateSql => [
    '''CREATE TABLE IF NOT EXISTS time_sessions (
id INTEGER PRIMARY KEY AUTOINCREMENT,
start_time TEXT NOT NULL,
end_time TEXT,
notes TEXT
)''',
    '''CREATE INDEX IF NOT EXISTS idx_time_start ON time_sessions(start_time)''',
    '''CREATE INDEX IF NOT EXISTS idx_time_end ON time_sessions(end_time)''',
    '''CREATE TABLE IF NOT EXISTS time_session_tags (
time_id INTEGER, tag_id INTEGER,
PRIMARY KEY(time_id, tag_id),
FOREIGN KEY(time_id) REFERENCES time_sessions(id),
FOREIGN KEY(tag_id) REFERENCES ${MetadataService.tableTags}(id)
)''',
  ];

  @override
  bool get isEnabled => true;

  @override
  int get version => 1;
}
