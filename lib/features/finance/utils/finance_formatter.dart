import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:telegraph/features/finance/models/transaction_model.dart';

class FinanceFormatter {
  static const _jsonEncoder = JsonEncoder.withIndent('  ');

  static String formatDailySummaryJson(
    DateTime date,
    List<TransactionModel> transactions,
  ) {
    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> tagBreakdown = {};

    for (final tx in transactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
        for (var tag in tx.displayTags) {
          tagBreakdown[tag] = (tagBreakdown[tag] ?? 0) + tx.amount;
        }
      }
    }

    final report = {
      "report": "Finance Summary",
      "date": DateFormat('yyyy-MM-dd').format(date),
      "overview": {
        "income": "+₹${totalIncome.toStringAsFixed(2)}",
        "expense": "-₹${totalExpense.toStringAsFixed(2)}",
        "net": "₹${(totalIncome - totalExpense).toStringAsFixed(2)}",
      },
      "expense_breakdown": tagBreakdown.map(
        (k, v) => MapEntry(k, "₹${v.toStringAsFixed(2)}"),
      ),
      "transactions": transactions
          .map(
            (t) => {
              "type": t.type,
              "amount": t.amount,
              "with": t.displayParticipants,
              "notes": t.notes,
              "tags": t.displayTags,
            },
          )
          .toList(),
    };

    // ✅ Fixed with triple quotes
    return """📊 **Finance Report**
```json
${_jsonEncoder.convert(report)}
```""";
  }
}
