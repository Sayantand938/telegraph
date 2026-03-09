import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'configure_dependencies.config.dart';
import 'services/ai/llm_client.dart';
import 'services/ai/conversation_manager.dart';
import 'services/ai/tool_executor.dart';
import 'services/ai/llm_service_new.dart';
import 'services/tools/tool_service.dart';
import 'services/repositories/llm_repository.dart';
import 'services/repositories/llm_repository_impl.dart';
import 'services/database/i_finance_database.dart';
import 'services/repositories/i_finance_repository.dart';
import 'services/repositories/finance_repository_impl.dart';
import 'services/database/i_session_database.dart';
import 'services/repositories/i_session_repository.dart';
import 'services/repositories/session_repository_impl.dart';
import 'core/config/app_config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies(AppConfig config) async {
  // Initialize generated dependencies
  getIt.init();

  // Register AI services with configuration
  _registerAIServices(config);

  // Register repositories
  _registerRepositories();
}

void _registerAIServices(AppConfig config) {
  // Register LlmClient as singleton
  getIt.registerLazySingleton<ILlmClient>(
    () => LlmClient(
      baseUrl: config.baseUrl,
      apiKey: config.apiKey,
      model: config.model,
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

  // Register LLM Repository (abstraction over LlmServiceNew)
  getIt.registerLazySingleton<ILlmRepository>(
    () => LlmRepository(getIt<LlmServiceNew>()),
  );
}

void _registerRepositories() {
  // Register Finance Repository
  getIt.registerLazySingleton<IFinanceRepository>(
    () => FinanceRepository(getIt<IFinanceDatabase>()),
  );

  // Register Session Repository
  getIt.registerLazySingleton<ISessionRepository>(
    () => SessionRepository(getIt<ISessionDatabase>()),
  );
}
