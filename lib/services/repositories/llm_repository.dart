import 'package:telegraph/services/ai/llm_service_new.dart';

/// Repository interface for LLM operations.
/// This abstraction enables easy mocking for testing and allows
/// swapping LLM implementations without affecting business logic.
abstract class ILlmRepository {
  /// Sends a message to the LLM and returns a response.
  /// [message] - The user's message
  /// [stream] - Whether to stream the response (if supported)
  Future<AiResponse> sendMessage(String message, {bool stream = false});

  /// Clears the conversation history.
  void clearHistory();

  /// Checks if the LLM service is healthy and reachable.
  Future<bool> healthCheck();

  /// Returns the name of the current model.
  String getModelName();
}
