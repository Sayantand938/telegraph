import 'package:logger/logger.dart';
import 'package:telegraph/models/session.dart';
import 'package:telegraph/services/repositories/i_session_repository.dart';
import 'package:telegraph/utils/tool_helpers.dart';
import 'package:telegraph/core/errors/exceptions.dart';
import 'package:telegraph/core/errors/result.dart';
import 'tool_definitions.dart';

List<Tool> getSessionTools(ISessionRepository repository) {
  final logger = Logger();
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
        final notes = args['notes'] as String?;
        String? startTime = args['start_time'] as String?;
        String? endTime = args['end_time'] as String?;

        startTime ??= DateTime.now().toIso8601String();

        if (!isValidIso8601(startTime)) {
          return Result.failure(
            ValidationException(
              'Invalid start_time format. Use ISO 8601 (e.g., 2025-01-15T10:30:00)',
              code: 'INVALID_DATE_FORMAT',
            ),
          );
        }
        if (endTime != null && !isValidIso8601(endTime)) {
          return Result.failure(
            ValidationException(
              'Invalid end_time format. Use ISO 8601 (e.g., 2025-01-15T10:30:00)',
              code: 'INVALID_DATE_FORMAT',
            ),
          );
        }

        if (endTime == null) {
          final activeSessionsResult = await repository
              .getSessionsByEndTimeIsNull();

          if (activeSessionsResult.isFailure) {
            return Result.failure(
              DatabaseException(
                'Failed to check active sessions: ${activeSessionsResult.error.message}',
                code: activeSessionsResult.error.code ?? 'DB_QUERY_FAILED',
                originalError: activeSessionsResult.error.originalError,
              ),
            );
          }

          final activeSessions = activeSessionsResult.value;

          if (activeSessions.isNotEmpty) {
            logger.log(
              Level.warning,
              'Cannot start session: active session exists (ID: ${activeSessions.first.id})',
            );
            return Result.failure(
              BusinessLogicException(
                'Cannot start a new active session. Session ${activeSessions.first.id} is already active. Please end it first using end_session(session_id=${activeSessions.first.id}).',
                code: 'ACTIVE_SESSION_EXISTS',
              ),
            );
          }
        }

        final hasOverlapResult = await repository.hasOverlap(
          startTime,
          endTime,
        );

        if (hasOverlapResult.isFailure) {
          final error = hasOverlapResult.error;
          if (error is BusinessLogicException) {
            return Result.failure(
              BusinessLogicException(
                error.message,
                code: error.code,
                originalError: error.originalError,
              ),
            );
          }
          return Result.failure(
            DatabaseException(
              'Failed to check session overlap: ${error.message}',
              code: error.code ?? 'DB_QUERY_FAILED',
              originalError: error.originalError,
            ),
          );
        }

        final hasOverlap = hasOverlapResult.value;

        if (hasOverlap) {
          logger.log(
            Level.warning,
            'Cannot start session: time overlap detected',
          );
          return Result.failure(
            BusinessLogicException(
              'Cannot start session: the specified time range overlaps with an existing session. Please choose a different time range.',
              code: 'SESSION_OVERLAP',
            ),
          );
        }

        logger.log(
          Level.info,
          'Starting session with notes: $notes, start: $startTime, end: $endTime',
        );

        final createResult = await repository.createSession(
          notes: notes,
          startTime: startTime,
          endTime: endTime,
        );

        return createResult.when(
          success: (id) {
            logger.log(Level.info, 'Session started successfully with ID: $id');
            return Result.success('Session started with ID: $id');
          },
          failure: (error) {
            logger.log(Level.error, 'Failed to create session: $error');
            if (error is DatabaseException) {
              return Result.failure(
                DatabaseException(
                  error.message,
                  code: error.code,
                  originalError: error.originalError,
                ),
              );
            }
            if (error is BusinessLogicException) {
              return Result.failure(
                BusinessLogicException(
                  error.message,
                  code: error.code,
                  originalError: error.originalError,
                ),
              );
            }
            return Result.failure(
              DatabaseException(
                'Failed to create session: ${error.message}',
                code: 'DB_CREATE_FAILED',
              ),
            );
          },
        );
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
        final notes = args['notes'] as String?;
        logger.log(Level.info, 'Ending active session with notes: $notes');

        final result = await repository.endActiveSession(notes: notes);

        return result.when(
          success: (endSessionResult) {
            if (endSessionResult == null) {
              logger.log(Level.warning, 'No active session found');
              return Result.failure(
                NotFoundException(
                  'No active session found',
                  code: 'NO_ACTIVE_SESSION',
                ),
              );
            }

            if (endSessionResult.splitOccurred) {
              logger.log(
                Level.info,
                'Active session ended with splitting: created ${endSessionResult.totalSessionsCreated} sessions. Final session ID: ${endSessionResult.finalSessionId}',
              );
              return Result.success(
                'Active session ended (crossed midnight - split into ${endSessionResult.totalSessionsCreated} daily sessions). Final session ID: ${endSessionResult.finalSessionId}',
              );
            }

            logger.log(
              Level.info,
              'Active session ${endSessionResult.finalSessionId} ended successfully',
            );
            return Result.success('Active session ended successfully');
          },
          failure: (error) {
            logger.log(Level.error, 'Failed to end active session: $error');
            if (error is NotFoundException) {
              return Result.failure(
                NotFoundException(
                  error.message,
                  code: error.code,
                  originalError: error.originalError,
                ),
              );
            }
            if (error is DatabaseException) {
              return Result.failure(
                DatabaseException(
                  error.message,
                  code: error.code,
                  originalError: error.originalError,
                ),
              );
            }
            return Result.failure(
              DatabaseException(
                'Failed to end active session: ${error.message}',
                code: 'DB_UPDATE_FAILED',
              ),
            );
          },
        );
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
        final status = args['status'] as String?;
        logger.log(Level.info, 'Listing sessions with status filter: $status');

        Result<List<Session>> result;

        if (status == 'active') {
          result = await repository.getSessionsByEndTimeIsNull();
        } else if (status == 'completed') {
          result = await repository.getSessionsByEndTimeIsNotNull();
        } else {
          result = await repository.getAllSessions();
        }

        if (result.isFailure) {
          final error = result.error;
          return Result.failure(
            DatabaseException(
              'Failed to get sessions: ${error.message}',
              code: error.code ?? 'DB_QUERY_FAILED',
              originalError: error.originalError,
            ),
          );
        }

        final filtered = result.value;

        if (filtered.isEmpty) {
          return Result.success('No sessions found');
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
        final resultStr = buffer.toString();
        logger.log(Level.info, 'Found ${filtered.length} sessions');
        return Result.success(resultStr);
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
        if (!args.containsKey('session_id')) {
          return Result.failure(
            ValidationException(
              'Missing required parameter: session_id',
              code: 'MISSING_PARAMETER',
            ),
          );
        }

        final id = args['session_id'] as int;
        logger.log(Level.info, 'Getting session $id');

        final result = await repository.getSession(id);

        if (result.isFailure) {
          final error = result.error;
          if (error is NotFoundException) {
            return Result.failure(
              NotFoundException(
                error.message,
                code: error.code,
                originalError: error.originalError,
              ),
            );
          }
          return Result.failure(
            DatabaseException(
              'Failed to get session: ${error.message}',
              code: error.code ?? 'DB_QUERY_FAILED',
              originalError: error.originalError,
            ),
          );
        }

        final session = result.value;
        if (session == null) {
          logger.log(Level.warning, 'Session $id not found');
          return Result.failure(
            NotFoundException(
              'Session $id not found',
              code: 'SESSION_NOT_FOUND',
            ),
          );
        }

        final resultStr =
            'Session $id:\n  Start: ${session.startTime}\n  End: ${session.endTime ?? 'N/A'}\n  Notes: ${session.notes ?? 'None'}';
        logger.log(Level.info, 'Session found: $resultStr');
        return Result.success(resultStr);
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
        if (!args.containsKey('session_id')) {
          return Result.failure(
            ValidationException(
              'Missing required parameter: session_id',
              code: 'MISSING_PARAMETER',
            ),
          );
        }

        final id = args['session_id'] as int;
        logger.log(Level.info, 'Deleting session $id');

        final result = await repository.deleteSession(id);

        if (result.isFailure) {
          final error = result.error;
          if (error is NotFoundException) {
            return Result.failure(
              NotFoundException(
                error.message,
                code: error.code,
                originalError: error.originalError,
              ),
            );
          }
          return Result.failure(
            DatabaseException(
              'Failed to delete session: ${error.message}',
              code: error.code ?? 'DB_DELETE_FAILED',
              originalError: error.originalError,
            ),
          );
        }

        final rowsAffected = result.value;
        if (rowsAffected > 0) {
          logger.log(Level.info, 'Session $id deleted successfully');
          return Result.success('Session $id deleted successfully');
        }
        logger.log(Level.warning, 'Session $id not found');
        return Result.failure(
          NotFoundException('Session $id not found', code: 'SESSION_NOT_FOUND'),
        );
      },
    ),
    Tool(
      name: 'get_active_session',
      description:
          'Get details of the most recent active session. Returns "No active sessions found" if none exist.',
      parameters: [],
      execute: (args) async {
        logger.log(Level.info, 'Getting most recent active session');

        final result = await repository.getMostRecentActiveSession();

        if (result.isFailure) {
          final error = result.error;
          if (error is NotFoundException) {
            return Result.failure(
              NotFoundException(
                'No active sessions found',
                code: 'NO_ACTIVE_SESSION',
              ),
            );
          }
          return Result.failure(
            DatabaseException(
              'Failed to get active session: ${error.message}',
              code: error.code ?? 'DB_QUERY_FAILED',
              originalError: error.originalError,
            ),
          );
        }

        final session = result.value;
        if (session == null) {
          logger.log(Level.warning, 'No active session found');
          return Result.failure(
            NotFoundException(
              'No active sessions found',
              code: 'NO_ACTIVE_SESSION',
            ),
          );
        }

        final resultStr =
            'Active Session ID: ${session.id}\n  Start: ${session.startTime}\n  Notes: ${session.notes ?? 'None'}';
        logger.log(Level.info, 'Found active session: $resultStr');
        return Result.success(resultStr);
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
        if (!args.containsKey('session_id')) {
          return Result.failure(
            ValidationException(
              'Missing required parameter: session_id',
              code: 'MISSING_PARAMETER',
            ),
          );
        }
        if (!args.containsKey('notes')) {
          return Result.failure(
            ValidationException(
              'Missing required parameter: notes',
              code: 'MISSING_PARAMETER',
            ),
          );
        }

        final id = args['session_id'] as int;
        final notes = args['notes'] as String;
        final append = args['append'] as bool? ?? true;

        logger.log(
          Level.info,
          'Updating notes for session $id (append: $append)',
        );

        final getResult = await repository.getSession(id);

        if (getResult.isFailure) {
          final error = getResult.error;
          if (error is NotFoundException) {
            return Result.failure(
              NotFoundException(
                error.message,
                code: error.code,
                originalError: error.originalError,
              ),
            );
          }
          return Result.failure(
            DatabaseException(
              'Failed to get session: ${error.message}',
              code: error.code ?? 'DB_QUERY_FAILED',
              originalError: error.originalError,
            ),
          );
        }

        final session = getResult.value;
        if (session == null) {
          logger.log(Level.warning, 'Session $id not found');
          return Result.failure(
            NotFoundException(
              'Session $id not found',
              code: 'SESSION_NOT_FOUND',
            ),
          );
        }

        String finalNotes;
        if (append && session.notes?.isNotEmpty == true) {
          finalNotes = '${session.notes}\n\n[Added later]: $notes';
        } else {
          finalNotes = notes;
        }

        final updatedSession = session.copyWith(notes: finalNotes);
        final updateResult = await repository.updateSession(updatedSession);

        return updateResult.when(
          success: (rowsAffected) {
            if (rowsAffected > 0) {
              logger.log(Level.info, 'Session $id notes updated successfully');
              return Result.success(
                'Session $id notes updated successfully.\nCurrent notes:\n$finalNotes',
              );
            }
            logger.log(Level.warning, 'Failed to update session $id');
            return Result.failure(
              DatabaseException(
                'Failed to update session $id',
                code: 'DB_UPDATE_FAILED',
              ),
            );
          },
          failure: (error) {
            logger.log(Level.error, 'Failed to update session $id: $error');
            return Result.failure(
              DatabaseException(
                'Failed to update session $id: ${error.message}',
                code: error.code ?? 'DB_UPDATE_FAILED',
                originalError: error.originalError,
              ),
            );
          },
        );
      },
    ),
  ];
}
