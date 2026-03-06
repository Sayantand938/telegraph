import 'package:telegraph/core/base_command_handler.dart';
import 'package:telegraph/core/utils/command_parser.dart';
import 'package:telegraph/core/utils/response_formatter.dart';
import 'package:telegraph/core/utils/response_codes.dart';
import 'package:telegraph/core/utils/formatters.dart';
import 'package:telegraph/features/finance/services/finance_database_service.dart';
import 'package:telegraph/features/finance/utils/finance_formatter.dart';

class FinanceCommandHandler extends BaseCommandHandler {
  final FinanceDatabaseService dbService;

  FinanceCommandHandler(this.dbService, {super.clock});

  @override
  String get moduleKey => 'finance';

  @override
  Future<String> handle(String input) async {
    final raw = input.toLowerCase().trim();
    if (raw.startsWith("$moduleKey log")) return await _handleFinanceLog(input);
    if (raw.startsWith("$moduleKey summary")) {
      return await _handleFinanceSummary(input);
    }
    if (raw.startsWith("$moduleKey delete")) {
      return performDelete(input, dbService.deleteTransaction);
    }
    return unknownSubCommand();
  }

  @override
  String get helpText =>
      "**Finance:**\n"
      "- `finance log [type] [amount] [date] [\"Note\"] @people #tags`\n"
      "- `finance summary` | `finance delete [id]`";

  Future<String> _handleFinanceLog(String input) async {
    final cmd = ParsedCommand.parse(input, clock: clock);
    if (cmd.args.length < 2) {
      return ResponseFormatter.error(
        "Format: `finance log [type] [amount] [date] [\"Note\"] @people #tags`",
        errorCode: ErrorCode.invalidFormat,
      );
    }

    final type = cmd.args[0].trim().toLowerCase();
    final amount = double.tryParse(cmd.args[1].trim()) ?? 0.0;

    if (amount <= 0) {
      return ResponseFormatter.error(
        "Amount must be positive.",
        errorCode: ErrorCode.amountError,
      );
    }
    if (!['income', 'expense'].contains(type)) {
      return ResponseFormatter.error(
        "Type must be 'income' or 'expense'.",
        errorCode: ErrorCode.typeError,
      );
    }

    final date = cmd.date ?? clock();

    await dbService.recordTransaction(
      amount: amount,
      type: type,
      date: date,
      notes: cmd.notes,
      tags: cmd.tags,
      participants: cmd.participants,
    );

    return ResponseFormatter.success(
      "Logged",
      successCode: SuccessCode.transactionLogged,
      data: {
        "type": type,
        "amount": amount,
        "notes": cmd.notes.isEmpty ? "(no note)" : cmd.notes,
        "date": Formatters.formatDate(date),
        "tags": cmd.tags.map((t) => '#$t').toList(),
        "with": cmd.participants.map((p) => '@$p').toList(),
      },
    );
  }

  Future<String> _handleFinanceSummary(String input) async {
    final cmd = ParsedCommand.parse(input, clock: clock);
    final date = cmd.date ?? clock();
    final transactions = await dbService.getTransactionsByDate(date);
    return transactions.isEmpty
        ? "📅 No records."
        : FinanceFormatter.formatDailySummaryJson(date, transactions);
  }
}
