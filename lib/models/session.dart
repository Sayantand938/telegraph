import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

@freezed
abstract class Session with _$Session {
  const factory Session({
    int? id,
    @JsonKey(name: 'start_time') required String startTime,
    @JsonKey(name: 'end_time') String? endTime,
    String? notes,
  }) = _Session;

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);
}
