// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatEntry {

 String get text; ChatEntryType get type; String? get reasoning; bool get isReasoningExpanded;
/// Create a copy of ChatEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatEntryCopyWith<ChatEntry> get copyWith => _$ChatEntryCopyWithImpl<ChatEntry>(this as ChatEntry, _$identity);

  /// Serializes this ChatEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatEntry&&(identical(other.text, text) || other.text == text)&&(identical(other.type, type) || other.type == type)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.isReasoningExpanded, isReasoningExpanded) || other.isReasoningExpanded == isReasoningExpanded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,type,reasoning,isReasoningExpanded);

@override
String toString() {
  return 'ChatEntry(text: $text, type: $type, reasoning: $reasoning, isReasoningExpanded: $isReasoningExpanded)';
}


}

/// @nodoc
abstract mixin class $ChatEntryCopyWith<$Res>  {
  factory $ChatEntryCopyWith(ChatEntry value, $Res Function(ChatEntry) _then) = _$ChatEntryCopyWithImpl;
@useResult
$Res call({
 String text, ChatEntryType type, String? reasoning, bool isReasoningExpanded
});




}
/// @nodoc
class _$ChatEntryCopyWithImpl<$Res>
    implements $ChatEntryCopyWith<$Res> {
  _$ChatEntryCopyWithImpl(this._self, this._then);

  final ChatEntry _self;
  final $Res Function(ChatEntry) _then;

/// Create a copy of ChatEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? type = null,Object? reasoning = freezed,Object? isReasoningExpanded = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ChatEntryType,reasoning: freezed == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String?,isReasoningExpanded: null == isReasoningExpanded ? _self.isReasoningExpanded : isReasoningExpanded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatEntry].
extension ChatEntryPatterns on ChatEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatEntry value)  $default,){
final _that = this;
switch (_that) {
case _ChatEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ChatEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  ChatEntryType type,  String? reasoning,  bool isReasoningExpanded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatEntry() when $default != null:
return $default(_that.text,_that.type,_that.reasoning,_that.isReasoningExpanded);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  ChatEntryType type,  String? reasoning,  bool isReasoningExpanded)  $default,) {final _that = this;
switch (_that) {
case _ChatEntry():
return $default(_that.text,_that.type,_that.reasoning,_that.isReasoningExpanded);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  ChatEntryType type,  String? reasoning,  bool isReasoningExpanded)?  $default,) {final _that = this;
switch (_that) {
case _ChatEntry() when $default != null:
return $default(_that.text,_that.type,_that.reasoning,_that.isReasoningExpanded);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatEntry implements ChatEntry {
  const _ChatEntry({required this.text, required this.type, this.reasoning, this.isReasoningExpanded = false});
  factory _ChatEntry.fromJson(Map<String, dynamic> json) => _$ChatEntryFromJson(json);

@override final  String text;
@override final  ChatEntryType type;
@override final  String? reasoning;
@override@JsonKey() final  bool isReasoningExpanded;

/// Create a copy of ChatEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatEntryCopyWith<_ChatEntry> get copyWith => __$ChatEntryCopyWithImpl<_ChatEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatEntry&&(identical(other.text, text) || other.text == text)&&(identical(other.type, type) || other.type == type)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.isReasoningExpanded, isReasoningExpanded) || other.isReasoningExpanded == isReasoningExpanded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,type,reasoning,isReasoningExpanded);

@override
String toString() {
  return 'ChatEntry(text: $text, type: $type, reasoning: $reasoning, isReasoningExpanded: $isReasoningExpanded)';
}


}

/// @nodoc
abstract mixin class _$ChatEntryCopyWith<$Res> implements $ChatEntryCopyWith<$Res> {
  factory _$ChatEntryCopyWith(_ChatEntry value, $Res Function(_ChatEntry) _then) = __$ChatEntryCopyWithImpl;
@override @useResult
$Res call({
 String text, ChatEntryType type, String? reasoning, bool isReasoningExpanded
});




}
/// @nodoc
class __$ChatEntryCopyWithImpl<$Res>
    implements _$ChatEntryCopyWith<$Res> {
  __$ChatEntryCopyWithImpl(this._self, this._then);

  final _ChatEntry _self;
  final $Res Function(_ChatEntry) _then;

/// Create a copy of ChatEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? type = null,Object? reasoning = freezed,Object? isReasoningExpanded = null,}) {
  return _then(_ChatEntry(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ChatEntryType,reasoning: freezed == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String?,isReasoningExpanded: null == isReasoningExpanded ? _self.isReasoningExpanded : isReasoningExpanded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
