import 'package:telegraph/services/ai/llm_service_new.dart';
import 'package:telegraph/services/repositories/llm_repository.dart';
import 'package:telegraph/core/errors/result.dart';
import 'package:telegraph/core/errors/exceptions.dart';

/// Concrete implementation of ILlmRepository.
/// Delegates to LlmServiceNew from the DI container and wraps errors in Result.
class LlmRepository implements ILlmRepository {
  final LlmServiceNew _llmService;

  LlmRepository(this._llmService);

  @override
  Future<Result<AiResponse>> sendMessage(
    String message, {
    bool stream = false,
  }) async {
    try {
      final response = await _llmService.sendMessage(message, stream: stream);
      return Result.success(response);
    } on AiServiceException catch (e) {
      return Result.failure(
        AiServiceException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        AiServiceException(
          'Failed to send message: $e',
          code: 'LLM_SEND_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  void clearHistory() {
    try {
      _llmService.clearHistory();
    } catch (e) {
      // clearHistory is best-effort, don't throw
      // But we could log the error if needed
    }
  }

  @override
  Future<Result<bool>> healthCheck() async {
    try {
      final isHealthy = await _llmService.healthCheck();
      return Result.success(isHealthy);
    } on AiServiceException catch (e) {
      return Result.failure(
        AiServiceException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        AiServiceException(
          'Health check failed: $e',
          code: 'LLM_HEALTH_CHECK_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  String getModelName() {
    try {
      return _llmService.getModelName();
    } catch (e) {
      // Return a default or throw? Since this is synchronous, we can throw
      // or return a placeholder. Let's return a safe default.
      return 'unknown';
    }
  }
}
