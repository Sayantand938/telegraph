import 'package:telegraph/services/repositories/i_session_repository.dart';
import 'package:telegraph/services/repositories/i_finance_repository.dart';
import 'tool_definitions.dart';
import 'session_tools.dart';
import 'finance_tools.dart';
import 'package:injectable/injectable.dart';
import 'package:telegraph/core/errors/exceptions.dart';
import 'package:telegraph/core/errors/result.dart';

@injectable
class ToolService {
  final ISessionRepository _sessionRepository;
  final IFinanceRepository _financeRepository;

  ToolService(this._sessionRepository, this._financeRepository);

  List<Tool> get tools => [
    ...getSessionTools(_sessionRepository),
    ...getFinanceTools(_financeRepository),
  ];

  List<Map<String, dynamic>> getToolSchemas() {
    return tools.map((tool) => tool.toSchema()).toList();
  }

  Future<Result<String>> executeTool(
    String toolName,
    Map<String, dynamic> args,
  ) async {
    try {
      final tool = tools.firstWhere(
        (t) => t.name == toolName,
        orElse: () => throw ToolException(toolName, 'Tool $toolName not found'),
      );
      return await tool.execute(args);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        ToolException(
          toolName,
          'Tool execution failed',
          originalError: e,
          code: 'TOOL_EXECUTION_ERROR',
        ),
      );
    }
  }
}
