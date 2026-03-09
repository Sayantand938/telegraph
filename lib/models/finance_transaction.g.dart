// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finance_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FinanceTransaction _$FinanceTransactionFromJson(Map<String, dynamic> json) =>
    _FinanceTransaction(
      id: (json['id'] as num?)?.toInt(),
      type: const TransactionTypeConverter().fromJson(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      transactionTime: json['transaction_time'] as String,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$FinanceTransactionToJson(_FinanceTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': const TransactionTypeConverter().toJson(instance.type),
      'amount': instance.amount,
      'transaction_time': instance.transactionTime,
      'note': instance.note,
    };
