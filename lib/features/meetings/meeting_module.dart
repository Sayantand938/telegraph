// lib/features/meetings/meeting_module.dart
import 'package:telegraph/core/module_interface.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/meetings/services/meeting_command_handler.dart';

class MeetingModule implements TelegraphModule {
  final MeetingCommandHandler _handler;

  MeetingModule(this._handler);

  @override
  String get name => "Meetings Tracker";

  @override
  FeatureCommandHandler get handler => _handler;

  @override
  List<String> get onCreateSql => [
    '''CREATE TABLE IF NOT EXISTS meeting_sessions (
id INTEGER PRIMARY KEY AUTOINCREMENT,
start_time TEXT NOT NULL,
end_time TEXT,
notes TEXT
)''',
    '''CREATE INDEX IF NOT EXISTS idx_meeting_start ON meeting_sessions(start_time)''',
    '''CREATE INDEX IF NOT EXISTS idx_meeting_end ON meeting_sessions(end_time)''',
    '''CREATE TABLE IF NOT EXISTS meeting_session_tags (
meeting_id INTEGER, tag_id INTEGER,
PRIMARY KEY(meeting_id, tag_id),
FOREIGN KEY(meeting_id) REFERENCES meeting_sessions(id),
FOREIGN KEY(tag_id) REFERENCES ${MetadataService.tableTags}(id)
)''',
    '''CREATE TABLE IF NOT EXISTS meeting_session_participants (
meeting_id INTEGER, participant_id INTEGER,
PRIMARY KEY(meeting_id, participant_id),
FOREIGN KEY(meeting_id) REFERENCES meeting_sessions(id),
FOREIGN KEY(participant_id) REFERENCES ${MetadataService.tableParticipants}(id)
)''',
  ];

  @override
  bool get isEnabled => true;

  @override
  int get version => 1;
}
