import '../../models/session.dart';
import '../../services/database/session_database.dart';
import 'dart:developer' as developer;

class ToolParameter {
  final String name;
  final String type;
  final String description;
  final bool required;

  ToolParameter({
    required this.name,
    required this.type,
    required this.description,
    this.required = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'required': required,
    };
  }
}

class Tool {
  final String name;
  final String description;
  final List<ToolParameter> parameters;
  final Future<String> Function(Map<String, dynamic> args) execute;

  Tool({
    required this.name,
    required this.description,
    required this.parameters,
    required this.execute,
  });

  Map<String, dynamic> toSchema() {
    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': {
          'type': 'object',
          'properties': {
            for (var param in parameters)
              param.name: {
                'type': param.type,
                'description': param.description,
              },
          },
          'required': parameters
              .where((p) => p.required)
              .map((p) => p.name)
              .toList(),
        },
      },
    };
  }
}

class ToolService {
  static final ToolService _instance = ToolService._internal();
  factory ToolService() => _instance;
  ToolService._internal();

  final SessionDatabase _db = SessionDatabase();

  List<Tool> get tools => [
    Tool(
      name: 'start_session',
      description: 'Start a new session with optional note and custom times',
      parameters: [
        ToolParameter(
          name: 'notes',
          type: 'string',
          description: 'Optional notes for this session',
          required: false,
        ),
        ToolParameter(
          name: 'start_time',
          type: 'string',
          description:
              'Optional start time (ISO 8601 format, e.g., 2025-01-15T10:30:00). Defaults to now.',
          required: false,
        ),
        ToolParameter(
          name: 'end_time',
          type: 'string',
          description:
              'Optional end time (ISO 8601 format). Omit for active sessions.',
          required: false,
        ),
      ],
      execute: (args) async {
        try {
          final notes = args['notes'] as String?;
          String? startTime = args['start_time'] as String?;
          String? endTime = args['end_time'] as String?;

          // Default start time to now if not provided
          if (startTime == null) {
            startTime = DateTime.now().toIso8601String();
          }

          // Validate time format if provided
          if (startTime != null) {
            try {
              DateTime.parse(startTime);
            } catch (e) {
              return 'Invalid start_time format. Use ISO 8601 (e.g., 2025-01-15T10:30:00)';
            }
          }
          if (endTime != null) {
            try {
              DateTime.parse(endTime);
            } catch (e) {
              return 'Invalid end_time format. Use ISO 8601 (e.g., 2025-01-15T10:30:00)';
            }
          }

          // Check for active sessions (if new session is active or starts in future)
          if (endTime == null) {
            final allSessions = await _db.getAllSessions();
            final activeSessions = allSessions
                .where((s) => s.endTime == null)
                .toList();

            if (activeSessions.isNotEmpty) {
              developer.log(
                'Cannot start session: active session exists (ID: ${activeSessions.first.id})',
              );
              return 'Cannot start a new active session. Session ${activeSessions.first.id} is already active. Please end it first using end_session(session_id=${activeSessions.first.id}).';
            }
          }

          // Check for time overlap with any existing session
          final hasOverlap = await _db.hasOverlap(startTime, endTime);
          if (hasOverlap) {
            developer.log('Cannot start session: time overlap detected');
            return 'Cannot start session: the specified time range overlaps with an existing session. Please choose a different time range.';
          }

          developer.log(
            'Starting session with notes: $notes, start: $startTime, end: $endTime',
          );
          final id = await _db.createSession(
            notes: notes,
            startTime: startTime,
            endTime: endTime,
          );
          developer.log('Session started successfully with ID: $id');
          return 'Session started with ID: $id';
        } catch (e, stackTrace) {
          developer.log('Error starting session: $e', stackTrace: stackTrace);
          return 'Error starting session: $e';
        }
      },
    ),
    Tool(
      name: 'end_session',
      description: 'End a session by ID with optional notes',
      parameters: [
        ToolParameter(
          name: 'session_id',
          type: 'integer',
          description: 'The ID of the session to end',
          required: true,
        ),
        ToolParameter(
          name: 'notes',
          type: 'string',
          description: 'Optional notes to add when ending',
          required: false,
        ),
      ],
      execute: (args) async {
        try {
          final id = args['session_id'] as int;

          // Check if session exists and is active
          final session = await _db.getSession(id);
          if (session == null) {
            developer.log('Session $id not found');
            return 'Session $id not found';
          }

          if (session.endTime != null) {
            developer.log('Session $id is already ended');
            return 'Session $id is already ended (ended at: ${session.endTime})';
          }

          final notes = args['notes'] as String?;
          developer.log('Ending session $id with notes: $notes');
          final result = await _db.endSession(id, notes: notes);
          if (result > 0) {
            developer.log('Session $id ended successfully');
            return 'Session $id ended successfully';
          }
          developer.log('Session $id not found');
          return 'Session $id not found';
        } catch (e, stackTrace) {
          developer.log('Error ending session: $e', stackTrace: stackTrace);
          return 'Error ending session: $e';
        }
      },
    ),
    Tool(
      name: 'list_sessions',
      description: 'List all sessions, optionally filtered by status',
      parameters: [
        ToolParameter(
          name: 'status',
          type: 'string',
          description:
              'Filter by "active" (no end_time) or "completed" (has end_time)',
          required: false,
        ),
      ],
      execute: (args) async {
        try {
          final status = args['status'] as String?;
          developer.log('Listing sessions with status filter: $status');
          final allSessions = await _db.getAllSessions();

          List<Session> filtered = allSessions;
          if (status == 'active') {
            filtered = allSessions.where((s) => s.endTime == null).toList();
          } else if (status == 'completed') {
            filtered = allSessions.where((s) => s.endTime != null).toList();
          }

          if (filtered.isEmpty) {
            return 'No sessions found';
          }

          final buffer = StringBuffer();
          buffer.writeln('Sessions:');
          for (final session in filtered) {
            buffer.writeln(
              '  ID: ${session.id} | Start: ${session.startTime} | End: ${session.endTime ?? 'N/A'}',
            );
            if (session.notes != null && session.notes!.isNotEmpty) {
              buffer.writeln('    Notes: ${session.notes}');
            }
          }
          final result = buffer.toString();
          developer.log('Found ${filtered.length} sessions');
          return result;
        } catch (e, stackTrace) {
          developer.log('Error listing sessions: $e', stackTrace: stackTrace);
          return 'Error listing sessions: $e';
        }
      },
    ),
    Tool(
      name: 'get_session',
      description: 'Get details of a specific session by ID',
      parameters: [
        ToolParameter(
          name: 'session_id',
          type: 'integer',
          description: 'The ID of the session to retrieve',
          required: true,
        ),
      ],
      execute: (args) async {
        try {
          final id = args['session_id'] as int;
          developer.log('Getting session $id');
          final session = await _db.getSession(id);
          if (session == null) {
            developer.log('Session $id not found');
            return 'Session $id not found';
          }
          final result =
              'Session $id:\n  Start: ${session.startTime}\n  End: ${session.endTime ?? 'N/A'}\n  Notes: ${session.notes ?? 'None'}';
          developer.log('Session found: $result');
          return result;
        } catch (e, stackTrace) {
          developer.log('Error getting session: $e', stackTrace: stackTrace);
          return 'Error getting session: $e';
        }
      },
    ),
    Tool(
      name: 'delete_session',
      description: 'Delete a session by ID',
      parameters: [
        ToolParameter(
          name: 'session_id',
          type: 'integer',
          description: 'The ID of the session to delete',
          required: true,
        ),
      ],
      execute: (args) async {
        try {
          final id = args['session_id'] as int;
          developer.log('Deleting session $id');
          final result = await _db.deleteSession(id);
          if (result > 0) {
            developer.log('Session $id deleted successfully');
            return 'Session $id deleted successfully';
          }
          developer.log('Session $id not found');
          return 'Session $id not found';
        } catch (e, stackTrace) {
          developer.log('Error deleting session: $e', stackTrace: stackTrace);
          return 'Error deleting session: $e';
        }
      },
    ),
    Tool(
      name: 'get_active_session',
      description:
          'Get details of the most recent active session. Returns "No active sessions found" if none exist.',
      parameters: [],
      execute: (args) async {
        try {
          developer.log('Getting most recent active session');
          final allSessions = await _db.getAllSessions();
          final activeSessions = allSessions
              .where((s) => s.endTime == null)
              .toList();

          if (activeSessions.isEmpty) {
            developer.log('No active sessions found');
            return 'No active sessions found';
          }

          // Sort by start time descending (most recent first)
          activeSessions.sort((a, b) => b.startTime.compareTo(a.startTime));
          final session = activeSessions.first;

          final result =
              'Active Session ID: ${session.id}\n  Start: ${session.startTime}\n  Notes: ${session.notes ?? 'None'}';
          developer.log('Found active session: $result');
          return result;
        } catch (e, stackTrace) {
          developer.log(
            'Error getting active session: $e',
            stackTrace: stackTrace,
          );
          return 'Error getting active session: $e';
        }
      },
    ),
    Tool(
      name: 'update_session_notes',
      description: 'Add or append notes to an existing session',
      parameters: [
        ToolParameter(
          name: 'session_id',
          type: 'integer',
          description: 'The ID of the session to update',
          required: true,
        ),
        ToolParameter(
          name: 'notes',
          type: 'string',
          description: 'Notes to add or append to the session',
          required: true,
        ),
        ToolParameter(
          name: 'append',
          type: 'boolean',
          description:
              'If true, append notes to existing; if false, overwrite (default: true)',
          required: false,
        ),
      ],
      execute: (args) async {
        try {
          final id = args['session_id'] as int;
          final notes = args['notes'] as String;
          final append = args['append'] as bool? ?? true;

          developer.log('Updating notes for session $id (append: $append)');

          final session = await _db.getSession(id);
          if (session == null) {
            developer.log('Session $id not found');
            return 'Session $id not found';
          }

          String finalNotes;
          if (append && session.notes?.isNotEmpty == true) {
            finalNotes = '${session.notes}\n\n[Added later]: $notes';
          } else {
            finalNotes = notes;
          }

          final updatedSession = session.copyWith(notes: finalNotes);
          final result = await _db.updateSession(updatedSession);

          if (result > 0) {
            developer.log('Session $id notes updated successfully');
            return 'Session $id notes updated successfully.\nCurrent notes:\n$finalNotes';
          }
          developer.log('Failed to update session $id');
          return 'Failed to update session $id';
        } catch (e, stackTrace) {
          developer.log(
            'Error updating session notes: $e',
            stackTrace: stackTrace,
          );
          return 'Error updating session notes: $e';
        }
      },
    ),
  ];

  List<Map<String, dynamic>> getToolSchemas() {
    return tools.map((tool) => tool.toSchema()).toList();
  }

  Future<String> executeTool(String toolName, Map<String, dynamic> args) async {
    final tool = tools.firstWhere(
      (t) => t.name == toolName,
      orElse: () => throw Exception('Tool $toolName not found'),
    );
    return await tool.execute(args);
  }
}
