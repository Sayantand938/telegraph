import 'package:freezed_annotation/freezed_annotation.dart';

part 'finance_transaction.freezed.dart';
part 'finance_transaction.g.dart';

enum TransactionType { income, expense }

class TransactionTypeConverter
    implements JsonConverter<TransactionType, String> {
  const TransactionTypeConverter();

  @override
  TransactionType fromJson(String json) {
    try {
      return TransactionType.values.firstWhere(
        (e) => e.name == json.toLowerCase(),
      );
    } catch (e) {
      return TransactionType.income; // Default to income for unknown values
    }
  }

  @override
  String toJson(TransactionType object) => object.name;
}

@freezed
abstract class FinanceTransaction with _$FinanceTransaction {
  const factory FinanceTransaction({
    int? id,
    @TransactionTypeConverter() required TransactionType type,
    required double amount,
    @JsonKey(name: 'transaction_time') required String transactionTime,
    String? note,
  }) = _FinanceTransaction;

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) =>
      _$FinanceTransactionFromJson(json);
}
