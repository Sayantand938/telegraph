// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Session _$SessionFromJson(Map<String, dynamic> json) => _Session(
  id: (json['id'] as num?)?.toInt(),
  startTime: json['start_time'] as String,
  endTime: json['end_time'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$SessionToJson(_Session instance) => <String, dynamic>{
  'id': instance.id,
  'start_time': instance.startTime,
  'end_time': instance.endTime,
  'notes': instance.notes,
};
