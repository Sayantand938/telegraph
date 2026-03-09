import 'package:telegraph/models/session.dart';
import 'package:telegraph/services/database/session_database.dart';
import 'package:telegraph/models/finance_transaction.dart';
import 'package:telegraph/services/database/finance_database.dart';
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
  final FinanceDatabase _financeDb = FinanceDatabase();

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
          startTime ??= DateTime.now().toIso8601String();

          // Validate time format
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
          final result = await _db.endActiveSession(notes: notes);

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
    // Finance Tools
    Tool(
      name: 'add_transaction',
      description: 'Record a financial transaction (income or expense)',
      parameters: [
        ToolParameter(
          name: 'type',
          type: 'string',
          description: 'Transaction type: "income" or "expense"',
          required: true,
        ),
        ToolParameter(
          name: 'amount',
          type: 'number',
          description: 'Transaction amount (positive number)',
          required: true,
        ),
        ToolParameter(
          name: 'event_timestamp',
          type: 'string',
          description:
              'Timestamp of transaction (ISO 8601 format, e.g., 2025-01-15T10:30:00). Defaults to now.',
          required: false,
        ),
        ToolParameter(
          name: 'note',
          type: 'string',
          description: 'Optional note about the transaction',
          required: false,
        ),
      ],
      execute: (args) async {
        try {
          final typeStr = args['type'] as String;
          final amount = args['amount'] as num;
          String? timestamp = args['event_timestamp'] as String?;
          final note = args['note'] as String?;

          // Validate transaction type
          final type = typeStr.toLowerCase() == 'expense'
              ? TransactionType.expense
              : TransactionType.income;

          // Default timestamp to now if not provided
          timestamp ??= DateTime.now().toIso8601String();

          // Validate timestamp format
          try {
            DateTime.parse(timestamp);
          } catch (e) {
            return 'Invalid event_timestamp format. Use ISO 8601 (e.g., 2025-01-15T10:30:00)';
          }

          // Validate amount
          if (amount <= 0) {
            return 'Amount must be a positive number';
          }

          developer.log(
            'Adding transaction: type=$type, amount=$amount, timestamp=$timestamp, note=$note',
          );

          final transaction = FinanceTransaction(
            type: type,
            amount: amount.toDouble(),
            eventTimestamp: timestamp,
            note: note,
          );

          final id = await _financeDb.createTransaction(transaction);
          developer.log('Transaction added successfully with ID: $id');

          final typeLabel = type == TransactionType.income
              ? 'Income'
              : 'Expense';
          return '$typeLabel transaction recorded (ID: $id)\n  Amount: \$${amount.toStringAsFixed(2)}\n  Time: $timestamp${note != null ? '\n  Note: $note' : ''}';
        } catch (e, stackTrace) {
          developer.log('Error adding transaction: $e', stackTrace: stackTrace);
          return 'Error adding transaction: $e';
        }
      },
    ),
    Tool(
      name: 'list_transactions',
      description:
          'List all financial transactions, optionally filtered by type or date range',
      parameters: [
        ToolParameter(
          name: 'type',
          type: 'string',
          description: 'Filter by "income" or "expense"',
          required: false,
        ),
        ToolParameter(
          name: 'start_date',
          type: 'string',
          description: 'Start date (ISO 8601 format, inclusive)',
          required: false,
        ),
        ToolParameter(
          name: 'end_date',
          type: 'string',
          description: 'End date (ISO 8601 format, inclusive)',
          required: false,
        ),
      ],
      execute: (args) async {
        try {
          final typeStr = args['type'] as String?;
          final startDateStr = args['start_date'] as String?;
          final endDateStr = args['end_date'] as String?;

          List<FinanceTransaction> transactions;

          if (startDateStr != null && endDateStr != null) {
            final start = DateTime.parse(startDateStr);
            final end = DateTime.parse(endDateStr);
            transactions = await _financeDb.getTransactionsByDateRange(
              start,
              end,
            );
          } else if (typeStr != null) {
            final type = typeStr.toLowerCase() == 'expense'
                ? TransactionType.expense
                : TransactionType.income;
            transactions = await _financeDb.getTransactionsByType(type);
          } else {
            transactions = await _financeDb.getAllTransactions();
          }

          if (transactions.isEmpty) {
            return 'No transactions found';
          }

          final buffer = StringBuffer();
          buffer.writeln('Financial Transactions:');
          double totalIncome = 0;
          double totalExpense = 0;

          for (final tx in transactions) {
            final typeLabel = tx.type == TransactionType.income
                ? 'Income'
                : 'Expense';
            buffer.writeln(
              '  ID ${tx.id}: [$typeLabel] \$${tx.amount.toStringAsFixed(2)} at ${tx.eventTimestamp}',
            );
            if (tx.note != null && tx.note!.isNotEmpty) {
              buffer.writeln('    Note: ${tx.note}');
            }

            if (tx.type == TransactionType.income) {
              totalIncome += tx.amount;
            } else {
              totalExpense += tx.amount;
            }
          }

          buffer.writeln('\nSummary:');
          buffer.writeln(
            '  Total Income: +\$${totalIncome.toStringAsFixed(2)}',
          );
          buffer.writeln(
            '  Total Expense: -\$${totalExpense.toStringAsFixed(2)}',
          );
          buffer.writeln(
            '  Net: \$${(totalIncome - totalExpense).toStringAsFixed(2)}',
          );

          final result = buffer.toString();
          developer.log('Listed ${transactions.length} transactions');
          return result;
        } catch (e, stackTrace) {
          developer.log(
            'Error listing transactions: $e',
            stackTrace: stackTrace,
          );
          return 'Error listing transactions: $e';
        }
      },
    ),
    Tool(
      name: 'get_transaction',
      description: 'Get details of a specific transaction by ID',
      parameters: [
        ToolParameter(
          name: 'transaction_id',
          type: 'integer',
          description: 'The ID of the transaction to retrieve',
          required: true,
        ),
      ],
      execute: (args) async {
        try {
          final id = args['transaction_id'] as int;
          developer.log('Getting transaction $id');
          final tx = await _financeDb.getTransaction(id);
          if (tx == null) {
            developer.log('Transaction $id not found');
            return 'Transaction $id not found';
          }
          final typeLabel = tx.type == TransactionType.income
              ? 'Income'
              : 'Expense';
          final result =
              'Transaction $id:\n  Type: $typeLabel\n  Amount: \$${tx.amount.toStringAsFixed(2)}\n  Time: ${tx.eventTimestamp}\n  Note: ${tx.note ?? 'None'}';
          developer.log('Transaction found: $result');
          return result;
        } catch (e, stackTrace) {
          developer.log(
            'Error getting transaction: $e',
            stackTrace: stackTrace,
          );
          return 'Error getting transaction: $e';
        }
      },
    ),
    Tool(
      name: 'delete_transaction',
      description: 'Delete a transaction by ID',
      parameters: [
        ToolParameter(
          name: 'transaction_id',
          type: 'integer',
          description: 'The ID of the transaction to delete',
          required: true,
        ),
      ],
      execute: (args) async {
        try {
          final id = args['transaction_id'] as int;
          developer.log('Deleting transaction $id');
          final result = await _financeDb.deleteTransaction(id);
          if (result > 0) {
            developer.log('Transaction $id deleted successfully');
            return 'Transaction $id deleted successfully';
          }
          developer.log('Transaction $id not found');
          return 'Transaction $id not found';
        } catch (e, stackTrace) {
          developer.log(
            'Error deleting transaction: $e',
            stackTrace: stackTrace,
          );
          return 'Error deleting transaction: $e';
        }
      },
    ),
    Tool(
      name: 'update_transaction',
      description: 'Update an existing transaction',
      parameters: [
        ToolParameter(
          name: 'transaction_id',
          type: 'integer',
          description: 'The ID of the transaction to update',
          required: true,
        ),
        ToolParameter(
          name: 'type',
          type: 'string',
          description: 'New type: "income" or "expense"',
          required: false,
        ),
        ToolParameter(
          name: 'amount',
          type: 'number',
          description: 'New amount (positive number)',
          required: false,
        ),
        ToolParameter(
          name: 'event_timestamp',
          type: 'string',
          description: 'New timestamp (ISO 8601 format)',
          required: false,
        ),
        ToolParameter(
          name: 'note',
          type: 'string',
          description: 'New note (replaces existing)',
          required: false,
        ),
      ],
      execute: (args) async {
        try {
          final id = args['transaction_id'] as int;
          developer.log('Updating transaction $id');

          final existing = await _financeDb.getTransaction(id);
          if (existing == null) {
            developer.log('Transaction $id not found');
            return 'Transaction $id not found';
          }

          TransactionType? type;
          if (args.containsKey('type')) {
            final typeStr = (args['type'] as String).toLowerCase();
            type = typeStr == 'expense'
                ? TransactionType.expense
                : TransactionType.income;
          }

          double? amount;
          if (args.containsKey('amount')) {
            final amt = args['amount'] as num;
            if (amt <= 0) {
              return 'Amount must be a positive number';
            }
            amount = amt.toDouble();
          }

          String? timestamp;
          if (args.containsKey('event_timestamp')) {
            final ts = args['event_timestamp'] as String;
            try {
              DateTime.parse(ts);
              timestamp = ts;
            } catch (e) {
              return 'Invalid event_timestamp format. Use ISO 8601 (e.g., 2025-01-15T10:30:00)';
            }
          }

          String? note;
          if (args.containsKey('note')) {
            note = args['note'] as String?;
          }

          final updated = existing.copyWith(
            type: type,
            amount: amount,
            eventTimestamp: timestamp,
            note: note,
          );

          final result = await _financeDb.updateTransaction(updated);
          if (result > 0) {
            developer.log('Transaction $id updated successfully');
            return 'Transaction $id updated successfully';
          }
          return 'Failed to update transaction $id';
        } catch (e, stackTrace) {
          developer.log(
            'Error updating transaction: $e',
            stackTrace: stackTrace,
          );
          return 'Error updating transaction: $e';
        }
      },
    ),
    Tool(
      name: 'get_financial_summary',
      description:
          'Get financial summary with totals for income, expenses, and net balance',
      parameters: [
        ToolParameter(
          name: 'period',
          type: 'string',
          description:
              'Time period: "today", "week", "month", "year", or "all"',
          required: false,
        ),
      ],
      execute: (args) async {
        try {
          final period = (args['period'] as String?)?.toLowerCase() ?? 'all';
          DateTime? start;
          DateTime? end;

          final now = DateTime.now();
          switch (period) {
            case 'today':
              start = DateTime(now.year, now.month, now.day);
              end = now;
              break;
            case 'week':
              start = now.subtract(Duration(days: now.weekday - 1));
              start = DateTime(start.year, start.month, start.day);
              end = now;
              break;
            case 'month':
              start = DateTime(now.year, now.month, 1);
              end = now;
              break;
            case 'year':
              start = DateTime(now.year, 1, 1);
              end = now;
              break;
            case 'all':
              start = null;
              end = null;
              break;
          }

          double income;
          double expense;

          if (start != null && end != null) {
            income = await _financeDb.getTotalByType(
              TransactionType.income,
              start: start,
              end: end,
            );
            expense = await _financeDb.getTotalByType(
              TransactionType.expense,
              start: start,
              end: end,
            );
          } else {
            income = await _financeDb.getTotalByType(TransactionType.income);
            expense = await _financeDb.getTotalByType(TransactionType.expense);
          }

          final buffer = StringBuffer();
          buffer.writeln(
            'Financial Summary${period != 'all' ? ' ($period)' : ''}:',
          );
          buffer.writeln('  Income: +\$${income.toStringAsFixed(2)}');
          buffer.writeln('  Expenses: -\$${expense.toStringAsFixed(2)}');
          buffer.writeln(
            '  Net Balance: \$${(income - expense).toStringAsFixed(2)}',
          );

          final result = buffer.toString();
          developer.log('Generated financial summary for period: $period');
          return result;
        } catch (e, stackTrace) {
          developer.log('Error generating summary: $e', stackTrace: stackTrace);
          return 'Error generating summary: $e';
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
