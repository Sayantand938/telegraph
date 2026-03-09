import 'llm_service_new.dart';

/// Legacy AiResponse class - kept for backward compatibility
class AiResponse {
  final String? reasoning;
  final String content;
  final List<Map<String, dynamic>>? toolCalls;

  AiResponse({this.reasoning, required this.content, this.toolCalls});
}

/// Legacy LlmService - now a thin wrapper around the new architecture
/// This class is DEPRECATED. Use LlmServiceNew directly via DI.
@Deprecated(
  'Use LlmServiceNew via GetIt instead. This wrapper maintains backward compatibility.',
)
class LlmService {
  late final LlmServiceNew _newService;

  LlmService(this._newService);

  void clearHistory() {
    _newService.clearHistory();
  }

  Future<bool> healthCheck() async {
    return await _newService.healthCheck();
  }

  String getModelName() {
    return _newService.getModelName();
  }

  Future<AiResponse> sendMessage(String message, {bool stream = false}) async {
    final response = await _newService.sendMessage(message, stream: stream);

    // Convert to legacy AiResponse format
    return AiResponse(
      reasoning: response.reasoning,
      content: response.content,
      toolCalls: response.toolCalls,
    );
  }
}
