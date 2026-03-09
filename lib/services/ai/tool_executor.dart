import 'llm_client.dart';
import 'package:telegraph/services/tools/tool_service.dart';
import 'package:logger/logger.dart';
import 'package:telegraph/core/errors/exceptions.dart';
import 'package:telegraph/core/errors/result.dart';

/// Result of a tool execution - now using Result pattern
class ToolExecutionResult {
  final String toolName;
  final Result<String> result;
  final int? executionTimeMs;

  ToolExecutionResult({
    required this.toolName,
    required this.result,
    this.executionTimeMs,
  });

  @override
  String toString() {
    return result.when(
      success: (value) =>
          'ToolExecutionResult(tool: $toolName, result: $value, time: ${executionTimeMs}ms)',
      failure: (error) =>
          'ToolExecutionResult(tool: $toolName, error: $error, time: ${executionTimeMs}ms)',
    );
  }
}

/// Orchestrates tool execution based on LLM tool calls
class ToolExecutor {
  final ToolService _toolService;
  final Logger _logger;

  ToolExecutor(this._toolService) : _logger = Logger();

  /// Execute a list of tool calls and return the results
  /// Tools are executed sequentially (for now - could be parallelized if independent)
  Future<List<ToolExecutionResult>> executeToolCalls(
    List<LlmToolCall> toolCalls,
  ) async {
    final results = <ToolExecutionResult>[];

    for (final toolCall in toolCalls) {
      final result = await _executeSingleTool(toolCall);
      results.add(result);
    }

    return results;
  }

  /// Execute a single tool call
  Future<ToolExecutionResult> _executeSingleTool(LlmToolCall toolCall) async {
    final stopwatch = Stopwatch()..start();

    try {
      _logger.log(
        Level.info,
        'Executing tool: ${toolCall.name} with args: ${toolCall.arguments}',
      );

      final result = await _toolService.executeTool(
        toolCall.name,
        toolCall.arguments,
      );

      stopwatch.stop();

      _logger.log(
        Level.info,
        'Tool ${toolCall.name} executed successfully in ${stopwatch.elapsedMilliseconds}ms',
      );

      return ToolExecutionResult(
        toolName: toolCall.name,
        result: result,
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();

      _logger.log(
        Level.error,
        'Tool ${toolCall.name} failed: $e',
        error: e,
        stackTrace: stackTrace,
      );

      // Wrap the exception in a ToolException if it's not already one
      final exception = e is AppException
          ? e
          : ToolException(
              toolCall.name,
              'Tool execution failed',
              originalError: e,
              code: 'TOOL_EXECUTION_ERROR',
            );

      return ToolExecutionResult(
        toolName: toolCall.name,
        result: Result.failure(exception),
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Convert tool execution results to messages that can be added to conversation history
  List<LlmMessage> resultsToMessages(List<ToolExecutionResult> results) {
    return results.map((result) {
      return result.result.when(
        success: (content) => LlmMessage.tool(content),
        failure: (error) {
          // Convert error to user-friendly message
          final errorMessage = error.toString();
          return LlmMessage.tool('Error: $errorMessage');
        },
      );
    }).toList();
  }
}
