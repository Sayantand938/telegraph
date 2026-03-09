import 'dart:developer' as developer;
import 'package:telegraph/models/finance_transaction.dart';
import 'package:telegraph/services/repositories/i_finance_repository.dart';
import 'package:telegraph/utils/tool_helpers.dart';
import 'package:telegraph/core/errors/exceptions.dart';
import 'package:telegraph/core/errors/result.dart';
import 'tool_definitions.dart';

List<Tool> getFinanceTools(IFinanceRepository repository) {
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
        // Validate required parameters
        if (!args.containsKey('type')) {
          return Result.failure(
            ValidationException(
              'Missing required parameter: type',
              code: 'MISSING_PARAMETER',
            ),
          );
        }
        if (!args.containsKey('amount')) {
          return Result.failure(
            ValidationException(
              'Missing required parameter: amount',
              code: 'MISSING_PARAMETER',
            ),
          );
        }

        final typeStr = args['type'] as String;
        final amount = args['amount'] as num;
        String? timestamp = args['transaction_time'] as String?;
        final note = args['note'] as String?;

        final type = parseTransactionType(typeStr);
        timestamp ??= DateTime.now().toIso8601String();

        if (!isValidIso8601(timestamp)) {
          return Result.failure(
            ValidationException(
              'Invalid transaction_time format. Use ISO 8601 (e.g., 2025-01-15T10:30:00)',
              code: 'INVALID_DATE_FORMAT',
            ),
          );
        }

        if (amount <= 0) {
          return Result.failure(
            ValidationException(
              'Amount must be a positive number',
              code: 'INVALID_AMOUNT',
            ),
          );
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

        final result = await repository.createTransaction(transaction);
        return result.when(
          success: (id) {
            developer.log('Transaction added successfully with ID: $id');
            final typeLabel = transactionTypeLabel(type);
            final message =
                '$typeLabel transaction recorded (ID: $id)\n  Amount: \$${amount.toStringAsFixed(2)}\n  Time: $timestamp${note != null ? '\n  Note: $note' : ''}';
            return Result.success(message);
          },
          failure: (error) {
            developer.log('Failed to create transaction: $error');
            return Result.failure(
              DatabaseException(
                error.message,
                code: error.code,
                originalError: error.originalError,
              ),
            );
          },
        );
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
        final typeStr = args['type'] as String?;
        final startDateStr = args['start_date'] as String?;
        final endDateStr = args['end_date'] as String?;

        // Validate date formats if provided
        if (startDateStr != null && !isValidIso8601(startDateStr)) {
          return Result.failure(
            ValidationException(
              'Invalid start_date format. Use ISO 8601 (e.g., 2025-01-15T10:30:00)',
              code: 'INVALID_DATE_FORMAT',
            ),
          );
        }
        if (endDateStr != null && !isValidIso8601(endDateStr)) {
          return Result.failure(
            ValidationException(
              'Invalid end_date format. Use ISO 8601 (e.g., 2025-01-15T10:30:00)',
              code: 'INVALID_DATE_FORMAT',
            ),
          );
        }

        Result<List<FinanceTransaction>> result;
        if (startDateStr != null && endDateStr != null) {
          final start = DateTime.parse(startDateStr);
          final end = DateTime.parse(endDateStr);
          result = await repository.getTransactionsByDateRange(start, end);
        } else if (typeStr != null) {
          final type = parseTransactionType(typeStr);
          result = await repository.getTransactionsByType(type);
        } else {
          result = await repository.getAllTransactions();
        }

        if (result.isFailure) {
          return Result.failure(
            DatabaseException(
              'Failed to get transactions: ${result.error.message}',
              code: result.error.code ?? 'DB_QUERY_FAILED',
              originalError: result.error.originalError,
            ),
          );
        }

        final transactions = result.value;

        if (transactions.isEmpty) {
          return Result.success('No transactions found');
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
        buffer.writeln('  Total Income: +\$${totalIncome.toStringAsFixed(2)}');
        buffer.writeln(
          '  Total Expense: -\$${totalExpense.toStringAsFixed(2)}',
        );
        buffer.writeln(
          '  Net: \$${(totalIncome - totalExpense).toStringAsFixed(2)}',
        );

        final resultStr = buffer.toString();
        developer.log('Listed ${transactions.length} transactions');
        return Result.success(resultStr);
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
        if (!args.containsKey('transaction_id')) {
          return Result.failure(
            ValidationException(
              'Missing required parameter: transaction_id',
              code: 'MISSING_PARAMETER',
            ),
          );
        }

        final id = args['transaction_id'] as int;
        developer.log('Getting transaction $id');

        final result = await repository.getTransaction(id);

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
              'Failed to get transaction: ${error.message}',
              code: error.code ?? 'DB_QUERY_FAILED',
              originalError: error.originalError,
            ),
          );
        }

        final tx = result.value;
        if (tx == null) {
          developer.log('Transaction $id not found');
          return Result.failure(
            NotFoundException(
              'Transaction $id not found',
              code: 'TRANSACTION_NOT_FOUND',
            ),
          );
        }

        final typeLabel = transactionTypeLabel(tx.type);
        final resultStr =
            'Transaction $id:\n  Type: $typeLabel\n  Amount: \$${tx.amount.toStringAsFixed(2)}\n  Time: ${tx.transactionTime}\n  Note: ${tx.note ?? 'None'}';
        developer.log('Transaction found: $resultStr');
        return Result.success(resultStr);
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
        if (!args.containsKey('transaction_id')) {
          return Result.failure(
            ValidationException(
              'Missing required parameter: transaction_id',
              code: 'MISSING_PARAMETER',
            ),
          );
        }

        final id = args['transaction_id'] as int;
        developer.log('Deleting transaction $id');

        final result = await repository.deleteTransaction(id);

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
              'Failed to delete transaction: ${error.message}',
              code: error.code ?? 'DB_DELETE_FAILED',
              originalError: error.originalError,
            ),
          );
        }

        final rowsAffected = result.value;
        if (rowsAffected > 0) {
          developer.log('Transaction $id deleted successfully');
          return Result.success('Transaction $id deleted successfully');
        }
        developer.log('Transaction $id not found');
        return Result.failure(
          NotFoundException(
            'Transaction $id not found',
            code: 'TRANSACTION_NOT_FOUND',
          ),
        );
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
        if (!args.containsKey('transaction_id')) {
          return Result.failure(
            ValidationException(
              'Missing required parameter: transaction_id',
              code: 'MISSING_PARAMETER',
            ),
          );
        }

        final id = args['transaction_id'] as int;
        developer.log('Updating transaction $id');

        final getResult = await repository.getTransaction(id);

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
              'Failed to get transaction: ${error.message}',
              code: error.code ?? 'DB_QUERY_FAILED',
              originalError: error.originalError,
            ),
          );
        }

        final existing = getResult.value;
        if (existing == null) {
          developer.log('Transaction $id not found');
          return Result.failure(
            NotFoundException(
              'Transaction $id not found',
              code: 'TRANSACTION_NOT_FOUND',
            ),
          );
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
            return Result.failure(
              ValidationException(
                'Amount must be a positive number',
                code: 'INVALID_AMOUNT',
              ),
            );
          }
          amount = amt.toDouble();
        }

        String? timestamp;
        if (args.containsKey('transaction_time')) {
          final ts = args['transaction_time'] as String;
          if (!isValidIso8601(ts)) {
            return Result.failure(
              ValidationException(
                'Invalid transaction_time format. Use ISO 8601 (e.g., 2025-01-15T10:30:00)',
                code: 'INVALID_DATE_FORMAT',
              ),
            );
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

        final updateResult = await repository.updateTransaction(updated);
        return updateResult.when(
          success: (rowsAffected) {
            if (rowsAffected > 0) {
              developer.log('Transaction $id updated successfully');
              return Result.success('Transaction $id updated successfully');
            }
            developer.log('Failed to update transaction $id');
            return Result.failure(
              DatabaseException(
                'Failed to update transaction $id',
                code: 'DB_UPDATE_FAILED',
              ),
            );
          },
          failure: (error) {
            developer.log('Failed to update transaction $id: $error');
            return Result.failure(
              DatabaseException(
                'Failed to update transaction $id: ${error.message}',
                code: error.code ?? 'DB_UPDATE_FAILED',
                originalError: error.originalError,
              ),
            );
          },
        );
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

        Result<double> incomeResult;
        Result<double> expenseResult;

        if (start != null && end != null) {
          incomeResult = await repository.getTotalByType(
            TransactionType.income,
            start: start,
            end: end,
          );
          expenseResult = await repository.getTotalByType(
            TransactionType.expense,
            start: start,
            end: end,
          );
        } else {
          incomeResult = await repository.getTotalByType(
            TransactionType.income,
          );
          expenseResult = await repository.getTotalByType(
            TransactionType.expense,
          );
        }

        if (incomeResult.isFailure) {
          return Result.failure(
            DatabaseException(
              'Failed to get income total: ${incomeResult.error.message}',
              code: incomeResult.error.code ?? 'DB_QUERY_FAILED',
              originalError: incomeResult.error.originalError,
            ),
          );
        }
        if (expenseResult.isFailure) {
          return Result.failure(
            DatabaseException(
              'Failed to get expense total: ${expenseResult.error.message}',
              code: expenseResult.error.code ?? 'DB_QUERY_FAILED',
              originalError: expenseResult.error.originalError,
            ),
          );
        }

        final income = incomeResult.value;
        final expense = expenseResult.value;

        final buffer = StringBuffer();
        buffer.writeln(
          'Financial Summary${period != 'all' ? ' ($period)' : ''}:',
        );
        buffer.writeln('  Income: +\$${income.toStringAsFixed(2)}');
        buffer.writeln('  Expenses: -\$${expense.toStringAsFixed(2)}');
        buffer.writeln(
          '  Net Balance: \$${(income - expense).toStringAsFixed(2)}',
        );

        final resultStr = buffer.toString();
        developer.log('Generated financial summary for period: $period');
        return Result.success(resultStr);
      },
    ),
  ];
}
