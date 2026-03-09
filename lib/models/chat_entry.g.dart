// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatEntry _$ChatEntryFromJson(Map<String, dynamic> json) => _ChatEntry(
  text: json['text'] as String,
  type: $enumDecode(_$ChatEntryTypeEnumMap, json['type']),
  reasoning: json['reasoning'] as String?,
  isReasoningExpanded: json['isReasoningExpanded'] as bool? ?? false,
);

Map<String, dynamic> _$ChatEntryToJson(_ChatEntry instance) =>
    <String, dynamic>{
      'text': instance.text,
      'type': _$ChatEntryTypeEnumMap[instance.type]!,
      'reasoning': instance.reasoning,
      'isReasoningExpanded': instance.isReasoningExpanded,
    };

const _$ChatEntryTypeEnumMap = {
  ChatEntryType.user: 'user',
  ChatEntryType.ai: 'ai',
  ChatEntryType.error: 'error',
  ChatEntryType.system: 'system',
  ChatEntryType.blank: 'blank',
};
