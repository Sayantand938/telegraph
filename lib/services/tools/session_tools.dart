import 'dart:developer' as developer;
import 'package:telegraph/models/session.dart';
import 'package:telegraph/services/database/session_database.dart';
import 'tool_definitions.dart';

List<Tool> getSessionTools(SessionDatabase db) {
  return [
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

          startTime ??= DateTime.now().toIso8601String();

          try {
            DateTime.parse(startTime);
          } catch (e) {
            return 'Invalid start_time format. Use ISO 8601 (e.g., 2025-01-15T10:30:00)';
          }
          if (endTime != null) {
            try {
              DateTime.parse(endTime);
            } catch (e) {
              return 'Invalid end_time format. Use ISO 8601 (e.g., 2025-01-15T10:30:00)';
            }
          }

          if (endTime == null) {
            final allSessions = await db.getAllSessions();
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

          final hasOverlap = await db.hasOverlap(startTime, endTime);
          if (hasOverlap) {
            developer.log('Cannot start session: time overlap detected');
            return 'Cannot start session: the specified time range overlaps with an existing session. Please choose a different time range.';
          }

          developer.log(
            'Starting session with notes: $notes, start: $startTime, end: $endTime',
          );
          final id = await db.createSession(
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
      description: 'End the currently active session with optional notes',
      parameters: [
        ToolParameter(
          name: 'notes',
          type: 'string',
          description: 'Optional notes to add when ending',
          required: false,
        ),
      ],
      execute: (args) async {
        try {
          final notes = args['notes'] as String?;
          developer.log('Ending active session with notes: $notes');
          final result = await db.endActiveSession(notes: notes);

          if (result == null) {
            developer.log('No active session found');
            return 'No active session found';
          }

          if (result.splitOccurred) {
            developer.log(
              'Active session ended with splitting: created ${result.totalSessionsCreated} sessions. Final session ID: ${result.finalSessionId}',
            );
            return 'Active session ended (crossed midnight - split into ${result.totalSessionsCreated} daily sessions). Final session ID: ${result.finalSessionId}';
          }

          developer.log(
            'Active session ${result.finalSessionId} ended successfully',
          );
          return 'Active session ended successfully';
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
          final allSessions = await db.getAllSessions();

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
          final session = await db.getSession(id);
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
          final result = await db.deleteSession(id);
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
          final allSessions = await db.getAllSessions();
          final activeSessions = allSessions
              .where((s) => s.endTime == null)
              .toList();

          if (activeSessions.isEmpty) {
            developer.log('No active sessions found');
            return 'No active sessions found';
          }

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

          final session = await db.getSession(id);
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
          final result = await db.updateSession(updatedSession);

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
}
