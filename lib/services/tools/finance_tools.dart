import 'dart:developer' as developer;
import 'package:telegraph/models/finance_transaction.dart';
import 'package:telegraph/services/database/i_finance_database.dart';
import 'package:telegraph/utils/tool_helpers.dart';
import 'tool_definitions.dart';

List<Tool> getFinanceTools(IFinanceDatabase db) {
  return [
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
          name: 'transaction_time',
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
        return await handleToolError('adding transaction', () async {
          final typeStr = args['type'] as String;
          final amount = args['amount'] as num;
          String? timestamp = args['transaction_time'] as String?;
          final note = args['note'] as String?;

          final type = parseTransactionType(typeStr);
          timestamp ??= DateTime.now().toIso8601String();

          if (!isValidIso8601(timestamp)) {
            return 'Invalid transaction_time format. Use ISO 8601 (e.g., 2025-01-15T10:30:00)';
          }

          if (amount <= 0) {
            return 'Amount must be a positive number';
          }

          developer.log(
            'Adding transaction: type=$type, amount=$amount, timestamp=$timestamp, note=$note',
          );

          final transaction = FinanceTransaction(
            type: type,
            amount: amount.toDouble(),
            transactionTime: timestamp,
            note: note,
          );

          final id = await db.createTransaction(transaction);
          developer.log('Transaction added successfully with ID: $id');

          final typeLabel = transactionTypeLabel(type);
          return '$typeLabel transaction recorded (ID: $id)\n  Amount: \$${amount.toStringAsFixed(2)}\n  Time: $timestamp${note != null ? '\n  Note: $note' : ''}';
        });
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
        return await handleToolError('listing transactions', () async {
          final typeStr = args['type'] as String?;
          final startDateStr = args['start_date'] as String?;
          final endDateStr = args['end_date'] as String?;

          List<FinanceTransaction> transactions;

          if (startDateStr != null && endDateStr != null) {
            if (!isValidIso8601(startDateStr) || !isValidIso8601(endDateStr)) {
              return 'Invalid date format. Use ISO 8601 (e.g., 2025-01-15T10:30:00)';
            }
            final start = DateTime.parse(startDateStr);
            final end = DateTime.parse(endDateStr);
            transactions = await db.getTransactionsByDateRange(start, end);
          } else if (typeStr != null) {
            final type = parseTransactionType(typeStr);
            transactions = await db.getTransactionsByType(type);
          } else {
            transactions = await db.getAllTransactions();
          }

          if (transactions.isEmpty) {
            return 'No transactions found';
          }

          final buffer = StringBuffer();
          buffer.writeln('Financial Transactions:');
          double totalIncome = 0;
          double totalExpense = 0;

          for (final tx in transactions) {
            final typeLabel = transactionTypeLabel(tx.type);
            buffer.writeln(
              '  ID ${tx.id}: [$typeLabel] \$${tx.amount.toStringAsFixed(2)} at ${tx.transactionTime}',
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
        });
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
        return await handleToolError('getting transaction', () async {
          final id = args['transaction_id'] as int;
          developer.log('Getting transaction $id');
          final tx = await db.getTransaction(id);
          if (tx == null) {
            developer.log('Transaction $id not found');
            return 'Transaction $id not found';
          }
          final typeLabel = transactionTypeLabel(tx.type);
          final result =
              'Transaction $id:\n  Type: $typeLabel\n  Amount: \$${tx.amount.toStringAsFixed(2)}\n  Time: ${tx.transactionTime}\n  Note: ${tx.note ?? 'None'}';
          developer.log('Transaction found: $result');
          return result;
        });
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
        return await handleToolError('deleting transaction', () async {
          final id = args['transaction_id'] as int;
          developer.log('Deleting transaction $id');
          final result = await db.deleteTransaction(id);
          if (result > 0) {
            developer.log('Transaction $id deleted successfully');
            return 'Transaction $id deleted successfully';
          }
          developer.log('Transaction $id not found');
          return 'Transaction $id not found';
        });
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
          name: 'transaction_time',
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
        return await handleToolError('updating transaction', () async {
          final id = args['transaction_id'] as int;
          developer.log('Updating transaction $id');

          final existing = await db.getTransaction(id);
          if (existing == null) {
            developer.log('Transaction $id not found');
            return 'Transaction $id not found';
          }

          TransactionType? type;
          if (args.containsKey('type')) {
            final typeStr = (args['type'] as String).toLowerCase();
            type = parseTransactionType(typeStr);
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
          if (args.containsKey('transaction_time')) {
            final ts = args['transaction_time'] as String;
            if (!isValidIso8601(ts)) {
              return 'Invalid transaction_time format. Use ISO 8601 (e.g., 2025-01-15T10:30:00)';
            }
            timestamp = ts;
          }

          String? note;
          if (args.containsKey('note')) {
            note = args['note'] as String?;
          }

          final updated = existing.copyWith(
            type: type ?? existing.type,
            amount: amount ?? existing.amount,
            transactionTime: timestamp ?? existing.transactionTime,
            note: note ?? existing.note,
          );

          final result = await db.updateTransaction(updated);
          if (result > 0) {
            developer.log('Transaction $id updated successfully');
            return 'Transaction $id updated successfully';
          }
          return 'Failed to update transaction $id';
        });
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
        return await handleToolError('generating financial summary', () async {
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
            income = await db.getTotalByType(
              TransactionType.income,
              start: start,
              end: end,
            );
            expense = await db.getTotalByType(
              TransactionType.expense,
              start: start,
              end: end,
            );
          } else {
            income = await db.getTotalByType(TransactionType.income);
            expense = await db.getTotalByType(TransactionType.expense);
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
        });
      },
    ),
  ];
}
