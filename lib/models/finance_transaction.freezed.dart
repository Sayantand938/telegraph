// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'finance_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FinanceTransaction {

 int? get id;@TransactionTypeConverter() TransactionType get type; double get amount;@JsonKey(name: 'transaction_time') String get transactionTime; String? get note;
/// Create a copy of FinanceTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinanceTransactionCopyWith<FinanceTransaction> get copyWith => _$FinanceTransactionCopyWithImpl<FinanceTransaction>(this as FinanceTransaction, _$identity);

  /// Serializes this FinanceTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinanceTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.transactionTime, transactionTime) || other.transactionTime == transactionTime)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,amount,transactionTime,note);

@override
String toString() {
  return 'FinanceTransaction(id: $id, type: $type, amount: $amount, transactionTime: $transactionTime, note: $note)';
}


}

/// @nodoc
abstract mixin class $FinanceTransactionCopyWith<$Res>  {
  factory $FinanceTransactionCopyWith(FinanceTransaction value, $Res Function(FinanceTransaction) _then) = _$FinanceTransactionCopyWithImpl;
@useResult
$Res call({
 int? id,@TransactionTypeConverter() TransactionType type, double amount,@JsonKey(name: 'transaction_time') String transactionTime, String? note
});




}
/// @nodoc
class _$FinanceTransactionCopyWithImpl<$Res>
    implements $FinanceTransactionCopyWith<$Res> {
  _$FinanceTransactionCopyWithImpl(this._self, this._then);

  final FinanceTransaction _self;
  final $Res Function(FinanceTransaction) _then;

/// Create a copy of FinanceTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? type = null,Object? amount = null,Object? transactionTime = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,transactionTime: null == transactionTime ? _self.transactionTime : transactionTime // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FinanceTransaction].
extension FinanceTransactionPatterns on FinanceTransaction {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinanceTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinanceTransaction() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinanceTransaction value)  $default,){
final _that = this;
switch (_that) {
case _FinanceTransaction():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinanceTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _FinanceTransaction() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id, @TransactionTypeConverter()  TransactionType type,  double amount, @JsonKey(name: 'transaction_time')  String transactionTime,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinanceTransaction() when $default != null:
return $default(_that.id,_that.type,_that.amount,_that.transactionTime,_that.note);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id, @TransactionTypeConverter()  TransactionType type,  double amount, @JsonKey(name: 'transaction_time')  String transactionTime,  String? note)  $default,) {final _that = this;
switch (_that) {
case _FinanceTransaction():
return $default(_that.id,_that.type,_that.amount,_that.transactionTime,_that.note);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id, @TransactionTypeConverter()  TransactionType type,  double amount, @JsonKey(name: 'transaction_time')  String transactionTime,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _FinanceTransaction() when $default != null:
return $default(_that.id,_that.type,_that.amount,_that.transactionTime,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FinanceTransaction implements FinanceTransaction {
  const _FinanceTransaction({this.id, @TransactionTypeConverter() required this.type, required this.amount, @JsonKey(name: 'transaction_time') required this.transactionTime, this.note});
  factory _FinanceTransaction.fromJson(Map<String, dynamic> json) => _$FinanceTransactionFromJson(json);

@override final  int? id;
@override@TransactionTypeConverter() final  TransactionType type;
@override final  double amount;
@override@JsonKey(name: 'transaction_time') final  String transactionTime;
@override final  String? note;

/// Create a copy of FinanceTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinanceTransactionCopyWith<_FinanceTransaction> get copyWith => __$FinanceTransactionCopyWithImpl<_FinanceTransaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FinanceTransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinanceTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.transactionTime, transactionTime) || other.transactionTime == transactionTime)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,amount,transactionTime,note);

@override
String toString() {
  return 'FinanceTransaction(id: $id, type: $type, amount: $amount, transactionTime: $transactionTime, note: $note)';
}


}

/// @nodoc
abstract mixin class _$FinanceTransactionCopyWith<$Res> implements $FinanceTransactionCopyWith<$Res> {
  factory _$FinanceTransactionCopyWith(_FinanceTransaction value, $Res Function(_FinanceTransaction) _then) = __$FinanceTransactionCopyWithImpl;
@override @useResult
$Res call({
 int? id,@TransactionTypeConverter() TransactionType type, double amount,@JsonKey(name: 'transaction_time') String transactionTime, String? note
});




}
/// @nodoc
class __$FinanceTransactionCopyWithImpl<$Res>
    implements _$FinanceTransactionCopyWith<$Res> {
  __$FinanceTransactionCopyWithImpl(this._self, this._then);

  final _FinanceTransaction _self;
  final $Res Function(_FinanceTransaction) _then;

/// Create a copy of FinanceTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? type = null,Object? amount = null,Object? transactionTime = null,Object? note = freezed,}) {
  return _then(_FinanceTransaction(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,transactionTime: null == transactionTime ? _self.transactionTime : transactionTime // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
