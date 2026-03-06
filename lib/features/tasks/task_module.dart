// lib/features/tasks/task_module.dart
import 'package:telegraph/core/module_interface.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/tasks/services/task_command_handler.dart';

class TaskModule implements TelegraphModule {
  final TaskCommandHandler _handler;

  TaskModule(this._handler);

  @override
  String get name => "Task Manager";

  @override
  FeatureCommandHandler get handler => _handler;

  @override
  List<String> get onCreateSql => [
    '''CREATE TABLE IF NOT EXISTS task_items (
id INTEGER PRIMARY KEY AUTOINCREMENT,
notes TEXT NOT NULL,
is_completed INTEGER DEFAULT 0,
created_at TEXT NOT NULL,
due_date TEXT,
completed_at TEXT
)''',
    '''CREATE INDEX IF NOT EXISTS idx_task_completed ON task_items(is_completed)''',
    '''CREATE INDEX IF NOT EXISTS idx_task_created ON task_items(created_at)''',
    '''CREATE TABLE IF NOT EXISTS task_tag_junction (
task_id INTEGER, tag_id INTEGER,
PRIMARY KEY(task_id, tag_id),
FOREIGN KEY(task_id) REFERENCES task_items(id),
FOREIGN KEY(tag_id) REFERENCES ${MetadataService.tableTags}(id)
)''',
    '''CREATE TABLE IF NOT EXISTS task_participant_junction (
task_id INTEGER, participant_id INTEGER,
PRIMARY KEY(task_id, participant_id),
FOREIGN KEY(task_id) REFERENCES task_items(id),
FOREIGN KEY(participant_id) REFERENCES ${MetadataService.tableParticipants}(id)
)''',
  ];

  @override
  bool get isEnabled => true;

  @override
  int get version => 1;
}
