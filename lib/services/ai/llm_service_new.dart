import 'dart:convert';
import 'llm_client.dart';
import 'conversation_manager.dart';
import 'tool_executor.dart';
import 'package:telegraph/services/tools/tool_service.dart';
import 'package:telegraph/core/errors/exceptions.dart';

/// Main service for interacting with the LLM
/// This is a facade that coordinates the specialized components
class LlmServiceNew {
  final ILlmClient _client;
  final ConversationManager _conversationManager;
  final ToolExecutor _toolExecutor;
  final ToolService _toolService;

  bool _initialized = false;
  String? _modelName;

  LlmServiceNew({
    required ILlmClient client,
    required ConversationManager conversationManager,
    required ToolExecutor toolExecutor,
    required ToolService toolService,
  }) : _client = client,
       _conversationManager = conversationManager,
       _toolExecutor = toolExecutor,
       _toolService = toolService;

  /// Initialize the service (load config if needed)
  Future<void> initialize() async {
    if (_initialized) return;

    _modelName = _client.modelName;
    _initialized = true;
  }

  /// Clear conversation history
  void clearHistory() {
    _conversationManager.clear();
  }

  /// Get the current model name
  String getModelName() {
    if (!_initialized) {
      throw AiServiceException(
        'Service not initialized. Call initialize() first.',
        code: 'NOT_INITIALIZED',
      );
    }
    return _modelName!;
  }

  /// Health check - verify LLM API is reachable
  Future<bool> healthCheck() async {
    return await _client.healthCheck();
  }

  /// Send a message to the LLM and get a response
  /// Handles tool calls automatically if present
  Future<AiResponse> sendMessage(String message, {bool stream = false}) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // Add user message to history
      _conversationManager.addUserMessage(message);

      // Get conversation context
      final history = _conversationManager.prepareContext();

      // Get tool schemas
      final toolSchemas = _toolService.getToolSchemas();
      final tools = toolSchemas
          .map(
            (schema) => LlmToolSchema(
              name: schema['function']['name'],
              description: schema['function']['description'],
              parameters: schema['function']['parameters'],
            ),
          )
          .toList();

      // Build request
      final request = LlmRequest(
        message: message,
        conversationHistory: history,
        tools: tools.isNotEmpty ? tools : null,
        stream: stream,
      );

      // Send to LLM
      final response = await _client.sendMessage(request);

      // If there are tool calls, execute them and get final response
      if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
        return await _handleToolCalls(response);
      }

      // Add assistant response to history
      _conversationManager.addAssistantMessage(
        response.content,
        reasoning: response.reasoning,
      );

      // Convert LlmToolCall objects to maps for backward compatibility
      final toolCallsMaps = response.toolCalls
          ?.map(
            (tc) => {
              'id': tc.id,
              'function': {
                'name': tc.name,
                'arguments': jsonEncode(tc.arguments),
              },
            },
          )
          .toList();

      return AiResponse(
        content: response.content,
        reasoning: response.reasoning,
        toolCalls: toolCallsMaps,
      );
    } catch (e) {
      throw AiServiceException(
        'Failed to send message',
        originalError: e,
        code: 'LLM_REQUEST_FAILED',
      );
    }
  }

  /// Handle tool calls by executing them and sending results back to LLM
  Future<AiResponse> _handleToolCalls(LlmResponse initialResponse) async {
    // Add the assistant's message with tool calls to history
    _conversationManager.addAssistantMessage(
      initialResponse.content,
      reasoning: initialResponse.reasoning,
      toolCalls: initialResponse.toolCalls,
    );

    // Execute tools
    final toolResults = await _toolExecutor.executeToolCalls(
      initialResponse.toolCalls!,
    );

    // Add tool results to history
    final toolMessages = _toolExecutor.resultsToMessages(toolResults);
    for (final msg in toolMessages) {
      _conversationManager.addToolMessage(msg.content);
    }

    // Get updated conversation context
    final updatedHistory = _conversationManager.prepareContext();

    // Get tool schemas again (in case tools changed)
    final toolSchemas = _toolService.getToolSchemas();
    final tools = toolSchemas
        .map(
          (schema) => LlmToolSchema(
            name: schema['function']['name'],
            description: schema['function']['description'],
            parameters: schema['function']['parameters'],
          ),
        )
        .toList();

    // Send follow-up request with tool results
    final followUpRequest = LlmRequest(
      message: '', // Empty message - history contains everything
      conversationHistory: updatedHistory,
      tools: tools.isNotEmpty ? tools : null,
      stream: false,
    );

    try {
      final finalResponse = await _client.sendMessage(followUpRequest);

      // Add final assistant response to history
      _conversationManager.addAssistantMessage(finalResponse.content);

      return AiResponse(
        content: finalResponse.content,
        reasoning: finalResponse.reasoning,
        toolCalls: null,
      );
    } catch (e) {
      throw AiServiceException(
        'Error after tool execution',
        originalError: e,
        code: 'TOOL_EXECUTION_FAILED',
      );
    }
  }
}

/// Response wrapper for compatibility with existing code
class AiResponse {
  final String? reasoning;
  final String content;
  final List<Map<String, dynamic>>? toolCalls;

  AiResponse({this.reasoning, required this.content, this.toolCalls});
}
