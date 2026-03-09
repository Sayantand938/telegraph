import 'package:get_it/get_it.dart';
import 'llm_service_new.dart';

/// Legacy AiResponse class - kept for backward compatibility
class AiResponse {
  final String? reasoning;
  final String content;
  final List<Map<String, dynamic>>? toolCalls;

  AiResponse({this.reasoning, required this.content, this.toolCalls});
}

/// Legacy LlmService - now a thin wrapper around the new architecture
/// Maintains singleton pattern for backward compatibility
class LlmService {
  static final LlmService _instance = LlmService._internal();
  factory LlmService() => _instance;
  LlmService._internal();

  late LlmServiceNew _newService;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Get the new service from GetIt
    _newService = GetIt.instance<LlmServiceNew>();
    await _newService.initialize();
    _initialized = true;
  }

  void clearHistory() {
    _newService.clearHistory();
  }

  Future<bool> healthCheck() async {
    if (!_initialized) {
      await initialize();
    }
    return await _newService.healthCheck();
  }

  String getModelName() {
    if (!_initialized) {
      throw Exception('Service not initialized. Call initialize() first.');
    }
    return _newService.getModelName();
  }

  Future<AiResponse> sendMessage(String message, {bool stream = false}) async {
    if (!_initialized) {
      await initialize();
    }

    final response = await _newService.sendMessage(message, stream: stream);

    // Convert to legacy AiResponse format
    return AiResponse(
      reasoning: response.reasoning,
      content: response.content,
      toolCalls: response.toolCalls,
    );
  }
}
