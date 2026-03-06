// lib/core/di/app_dependencies.dart
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/time/services/time_database_service.dart';
import 'package:telegraph/features/time/services/time_command_handler.dart';
import 'package:telegraph/features/meetings/services/meeting_database_service.dart';
import 'package:telegraph/features/meetings/services/meeting_command_handler.dart';
import 'package:telegraph/features/tasks/services/task_database_service.dart';
import 'package:telegraph/features/tasks/services/task_command_handler.dart';
import 'package:telegraph/features/finance/services/finance_database_service.dart';
import 'package:telegraph/features/finance/services/finance_command_handler.dart';
import 'package:telegraph/features/sleep/services/sleep_database_service.dart';
import 'package:telegraph/features/sleep/services/sleep_command_handler.dart';

class AppDependencies {
  final DatabaseManager dbManager;
  final MetadataService metadataService;

  late final TimeDatabaseService timeDbService;
  late final MeetingDatabaseService meetingDbService;
  late final TaskDatabaseService taskDbService;
  late final FinanceDatabaseService financeDbService;
  late final SleepDatabaseService sleepDbService;

  late final TimeCommandHandler timeHandler;
  late final MeetingCommandHandler meetingHandler;
  late final TaskCommandHandler taskHandler;
  late final FinanceCommandHandler financeHandler;
  late final SleepCommandHandler sleepHandler;

  AppDependencies({
    required this.dbManager,
    required this.metadataService,
    DateTime Function()? testClock,
  }) {
    final clock = testClock ?? (() => DateTime.now());

    // Initialize Database Services (share the same metadataService)
    timeDbService = TimeDatabaseService(
      dbManager: dbManager,
      metadataService: metadataService,
    );
    meetingDbService = MeetingDatabaseService(
      dbManager: dbManager,
      metadataService: metadataService,
    );
    taskDbService = TaskDatabaseService(
      dbManager: dbManager,
      metadataService: metadataService,
    );
    financeDbService = FinanceDatabaseService(
      dbManager: dbManager,
      metadataService: metadataService,
    );
    sleepDbService = SleepDatabaseService(
      dbManager: dbManager,
      metadataService: metadataService,
    );

    // Initialize Command Handlers (Inject dependencies)
    timeHandler = TimeCommandHandler(timeDbService, clock: clock);
    meetingHandler = MeetingCommandHandler(meetingDbService, clock: clock);
    taskHandler = TaskCommandHandler(taskDbService, clock: clock);
    financeHandler = FinanceCommandHandler(financeDbService, clock: clock);
    sleepHandler = SleepCommandHandler(sleepDbService, clock: clock);
  }
}
