import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'configure_dependencies.config.dart';
import 'services/ai/llm_client.dart';
import 'services/ai/conversation_manager.dart';
import 'services/ai/tool_executor.dart';
import 'services/ai/llm_service_new.dart';
import 'services/tools/tool_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  // Initialize generated dependencies
  getIt.init();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Register AI services
  _registerAIServices();
}

void _registerAIServices() {
  // Register LlmClient as singleton
  getIt.registerLazySingleton<ILlmClient>(
    () => LlmClient(
      baseUrl: dotenv.get('BASE_URL'),
      apiKey: dotenv.get('NVIDIA_API_KEY'),
      model: dotenv.get('MODEL'),
    ),
  );

  // Register ConversationManager as singleton (shared history)
  getIt.registerLazySingleton<ConversationManager>(
    () => ConversationManager(maxHistoryLength: 50),
  );

  // Register ToolExecutor as singleton
  getIt.registerLazySingleton<ToolExecutor>(
    () => ToolExecutor(getIt<ToolService>()),
  );

  // Register the new LlmService facade as singleton
  getIt.registerLazySingleton<LlmServiceNew>(
    () => LlmServiceNew(
      client: getIt<ILlmClient>(),
      conversationManager: getIt<ConversationManager>(),
      toolExecutor: getIt<ToolExecutor>(),
      toolService: getIt<ToolService>(),
    ),
  );
}
