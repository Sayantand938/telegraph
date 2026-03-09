import 'package:telegraph/services/ai/llm_service_new.dart';
import 'package:telegraph/services/repositories/llm_repository.dart';

/// Concrete implementation of ILlmRepository.
/// Delegates to LlmServiceNew from the DI container.
class LlmRepository implements ILlmRepository {
  final LlmServiceNew _llmService;

  LlmRepository(this._llmService);

  @override
  Future<AiResponse> sendMessage(String message, {bool stream = false}) async {
    return await _llmService.sendMessage(message, stream: stream);
  }

  @override
  void clearHistory() {
    _llmService.clearHistory();
  }

  @override
  Future<bool> healthCheck() async {
    return await _llmService.healthCheck();
  }

  @override
  String getModelName() {
    return _llmService.getModelName();
  }
}
