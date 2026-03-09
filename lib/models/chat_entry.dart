import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_entry.freezed.dart';
part 'chat_entry.g.dart';

enum ChatEntryType { user, ai, error, system, blank }

@freezed
abstract class ChatEntry with _$ChatEntry {
  const factory ChatEntry({
    required String text,
    required ChatEntryType type,
    String? reasoning,
    @Default(false) bool isReasoningExpanded,
  }) = _ChatEntry;

  factory ChatEntry.fromJson(Map<String, dynamic> json) =>
      _$ChatEntryFromJson(json);
}
