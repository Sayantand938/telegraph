import 'llm_client.dart';
import 'package:telegraph/services/tools/tool_service.dart';
import 'dart:developer' as developer;
import 'package:telegraph/core/errors/exceptions.dart';

/// Result of a tool execution
class ToolExecutionResult {
  final String toolName;
  final String result;
  final bool success;
  final String? error;
  final int? executionTimeMs;

  ToolExecutionResult({
    required this.toolName,
    required this.result,
    required this.success,
    this.error,
    this.executionTimeMs,
  });

  @override
  String toString() {
    if (success) {
      return 'ToolExecutionResult(tool: $toolName, result: $result, time: ${executionTimeMs}ms)';
    } else {
      return 'ToolExecutionResult(tool: $toolName, error: $error, time: ${executionTimeMs}ms)';
    }
  }
}

/// Orchestrates tool execution based on LLM tool calls
class ToolExecutor {
  final ToolService _toolService;

  ToolExecutor(this._toolService);

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
      developer.log(
        'Executing tool: ${toolCall.name} with args: ${toolCall.arguments}',
      );

      final result = await _toolService.executeTool(
        toolCall.name,
        toolCall.arguments,
      );

      stopwatch.stop();

      developer.log(
        'Tool ${toolCall.name} executed successfully in ${stopwatch.elapsedMilliseconds}ms',
      );

      return ToolExecutionResult(
        toolName: toolCall.name,
        result: result,
        success: true,
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();

      developer.log('Tool ${toolCall.name} failed: $e', stackTrace: stackTrace);

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
        result: '',
        success: false,
        error: exception.toString(),
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Convert tool execution results to messages that can be added to conversation history
  List<LlmMessage> resultsToMessages(List<ToolExecutionResult> results) {
    return results.map((result) {
      if (result.success) {
        return LlmMessage.tool(result.result);
      } else {
        // Convert error to user-friendly message
        final errorMessage = result.error ?? 'Unknown error';
        return LlmMessage.tool('Error: $errorMessage');
      }
    }).toList();
  }
}
