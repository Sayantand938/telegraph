// lib/core/utils/response_formatter.dart
import 'dart:convert';
import 'response_codes.dart';

class ResponseFormatter {
  static const _encoder = JsonEncoder.withIndent('  ');

  static String format(
    String title,
    Map<String, dynamic> data, {
    String? code,
  }) {
    // ✅ Create a copy to avoid mutating the original map
    final payload = <String, dynamic>{...data};
    if (code != null) payload['code'] = code;

    return '$title\n```json\n${_encoder.convert(payload)}\n```';
  }

  static String error(
    String message, {
    ErrorCode? errorCode,
    Map<String, dynamic>? details,
  }) {
    final Map<String, dynamic> payload = <String, dynamic>{
      'error': message,
      'code': errorCode?.code ?? ErrorCode.unknown.code,
    };
    if (details != null) payload['details'] = details;

    return format('🚨 **Error**', payload);
  }

  static String success(
    String title, {
    SuccessCode? successCode,
    Map<String, dynamic>? data,
  }) {
    // ✅ Ensure we always have a mutable map
    final Map<String, dynamic> payload = <String, dynamic>{
      ...(data ?? <String, dynamic>{}),
    };
    payload['code'] = successCode?.code ?? SuccessCode.success.code;

    return format('✅ **$title**', payload);
  }

  static String list(
    String title,
    List<Map<String, dynamic>> items, {
    String? emptyMessage,
    SuccessCode? successCode,
  }) {
    if (items.isEmpty) {
      return emptyMessage ?? '📭 **$title**\nNo items found.';
    }
    final Map<String, dynamic> payload = <String, dynamic>{
      'items': items,
      'count': items.length,
    };
    if (successCode != null) payload['code'] = successCode.code;
    return format('📋 **$title**', payload);
  }

  static String summary(
    String title,
    Map<String, dynamic> stats, {
    Map<String, dynamic>? details,
    SuccessCode? successCode,
  }) {
    final Map<String, dynamic> payload = <String, dynamic>{'stats': stats};
    if (details != null) payload['details'] = details;
    if (successCode != null) payload['code'] = successCode.code;
    return format('📊 **$title**', payload);
  }

  // Legacy helper (deprecated - use success() instead)
  static String formatResponse(String title, Map<String, dynamic> data) {
    return format('✅ **$title**', data);
  }
}
