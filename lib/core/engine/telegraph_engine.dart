// lib/core/engine/telegraph_engine.dart
import 'package:path_provider/path_provider.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/core/di/app_dependencies.dart';
import 'package:telegraph/core/module_registry.dart';
import 'package:telegraph/features/chat/services/command_service.dart';
import 'package:telegraph/features/chat/models/message_model.dart';
import 'package:telegraph/features/time/time_module.dart';
import 'package:telegraph/features/finance/finance_module.dart';
import 'package:telegraph/features/meetings/meeting_module.dart';
import 'package:telegraph/features/tasks/task_module.dart';
import 'package:telegraph/features/sleep/sleep_module.dart';
import 'package:telegraph/core/utils/response_codes.dart';
import 'package:telegraph/core/utils/logger.dart';

class TelegraphEngine {
  late DatabaseManager dbManager;
  late MetadataService metadataService;
  late AppDependencies dependencies;
  late CommandService commandService;
  late ModuleRegistry moduleRegistry;
  final String? dbPathOverride;
  bool _isInitialized = false;
  String? _initializationError;
  ErrorCode? _initializationErrorCode;

  TelegraphEngine({this.dbPathOverride});

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      String? baseDirectory = dbPathOverride;
      if (baseDirectory == null) {
        final docsDir = await getApplicationDocumentsDirectory();
        baseDirectory = docsDir.path;
      }

      if (baseDirectory != ':memory:') {
        await Logger.initFileLog(baseDirectory);
      }

      Logger.init('Starting TelegraphEngine initialization...');

      dbManager = DatabaseManager(dbPathOverride: dbPathOverride);
      metadataService = MetadataService(dbManager: dbManager);

      dependencies = AppDependencies(
        dbManager: dbManager,
        metadataService: metadataService,
      );

      moduleRegistry = ModuleRegistry();
      moduleRegistry.registerAll([
        TimeModule(dependencies.timeHandler),
        FinanceModule(dependencies.financeHandler),
        MeetingModule(dependencies.meetingHandler),
        TaskModule(dependencies.taskHandler),
        SleepModule(dependencies.sleepHandler),
      ]);

      final List<String> allSql = [
        ...moduleRegistry.allCreateSql,
        '''CREATE TABLE IF NOT EXISTS chat_history (
id INTEGER PRIMARY KEY AUTOINCREMENT,
text TEXT NOT NULL,
is_me INTEGER NOT NULL,
timestamp TEXT DEFAULT (datetime('now'))
)''',
        'CREATE INDEX IF NOT EXISTS idx_chat_timestamp ON chat_history(timestamp)',
      ];

      await dbManager.initialize(allSql);
      final db = await dbManager.database;
      await metadataService.initializeTables(db);

      commandService = CommandService(moduleRegistry.allHandlers);

      // ✅ Maintenance run on startup
      await runMaintenance();

      _isInitialized = true;
      Logger.init('✅ TelegraphEngine initialized successfully');
    } catch (e, stackTrace) {
      _initializationError = e.toString();
      _initializationErrorCode = ErrorCode.initializationError;
      Logger.error(
        'Engine init failed',
        tag: 'Engine',
        err: e,
        stack: stackTrace,
      );
      rethrow;
    }
  }

  /// ✅ RESTORED & EXPOSED: Cleans up old chat history
  Future<void> runMaintenance() async {
    try {
      final db = await dbManager.database;
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Delete everything that isn't from today
      await db.delete(
        'chat_history',
        where: "date(timestamp) != date(?)",
        whereArgs: [todayStr],
      );
      Logger.db('Maintenance: Stale chat history cleared.');
    } catch (e) {
      Logger.error('Maintenance failed', tag: 'DB', err: e);
    }
  }

  Future<List<MessageModel>> loadChatHistory() async {
    try {
      if (!_isInitialized) return [];
      final db = await dbManager.database;
      final res = await db.query('chat_history', orderBy: 'timestamp ASC');
      return res
          .map(
            (row) => MessageModel(
              text: row['text'] as String? ?? '',
              isMe: (row['is_me'] as int?) == 1,
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveMessageToHistory(MessageModel message) async {
    try {
      if (!_isInitialized) return;
      final db = await dbManager.database;
      await db.insert('chat_history', {
        'text': message.text,
        'is_me': message.isMe ? 1 : 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await dbManager.close();
    }
    _isInitialized = false;
  }

  bool get isReady => _isInitialized;
  String? get initializationError => _initializationError;
  ErrorCode? get initializationErrorCode => _initializationErrorCode;
  int get registeredModuleCount => moduleRegistry.count;
}
