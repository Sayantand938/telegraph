import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:telegraph/core/utils/response_formatter.dart';
import 'package:telegraph/core/utils/response_codes.dart';

void main() {
  group('ResponseFormatter JSON structure', () {
    test('success() should generate valid Markdown JSON with code', () {
      final response = ResponseFormatter.success(
        "Task Logged",
        successCode: SuccessCode.taskLogged,
        data: {"id": 123},
      );

      expect(response, contains("✅ **Task Logged**"));
      expect(response, contains("```json"));

      // Extract and parse the JSON block
      final jsonStr = response.split("```json")[1].split("```")[0].trim();
      final data = jsonDecode(jsonStr);

      expect(data['code'], 'TASK_003');
      expect(data['id'], 123);
    });

    test('error() should format error messages correctly', () {
      final response = ResponseFormatter.error(
        "Invalid ID",
        errorCode: ErrorCode.notFound,
      );

      expect(response, contains("🚨 **Error**"));

      final jsonStr = response.split("```json")[1].split("```")[0].trim();
      final data = jsonDecode(jsonStr);

      expect(data['error'], 'Invalid ID');
      expect(data['code'], 'ERR_003');
    });

    test('list() should handle empty lists gracefully', () {
      final response = ResponseFormatter.list(
        "History",
        [],
        emptyMessage: "Nothing here, Boss.",
      );
      expect(response, "Nothing here, Boss.");
    });
  });
}
