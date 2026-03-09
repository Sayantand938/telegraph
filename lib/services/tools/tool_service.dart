import 'package:telegraph/services/database/session_database.dart';
import 'package:telegraph/services/database/finance_database.dart';
import 'tool_definitions.dart';
import 'session_tools.dart';
import 'finance_tools.dart';

class ToolService {
  static final ToolService _instance = ToolService._internal();
  factory ToolService() => _instance;
  ToolService._internal();

  final SessionDatabase _sessionDb = SessionDatabase();
  final FinanceDatabase _financeDb = FinanceDatabase();

  List<Tool> get tools => [
    ...getSessionTools(_sessionDb),
    ...getFinanceTools(_financeDb),
  ];

  List<Map<String, dynamic>> getToolSchemas() {
    return tools.map((tool) => tool.toSchema()).toList();
  }

  Future<String> executeTool(String toolName, Map<String, dynamic> args) async {
    final tool = tools.firstWhere(
      (t) => t.name == toolName,
      orElse: () => throw Exception('Tool $toolName not found'),
    );
    return await tool.execute(args);
  }
}
