import 'package:telegraph/core/base_command_handler.dart';
import 'package:telegraph/core/utils/command_parser.dart';
import 'package:telegraph/core/utils/response_formatter.dart';
import 'package:telegraph/core/utils/response_codes.dart';
import 'package:telegraph/core/utils/formatters.dart';
import 'package:telegraph/features/tasks/services/task_database_service.dart';

class TaskCommandHandler extends BaseCommandHandler {
  final TaskDatabaseService dbService;
  TaskCommandHandler(this.dbService, {super.clock});

  @override
  String get moduleKey => 'task';

  @override
  Future<String> handle(String input) async {
    final raw = input.toLowerCase().trim();
    if (raw.startsWith("$moduleKey add")) return await _handleAdd(input);
    if (raw.startsWith("$moduleKey log")) return await _handleLog(input);
    if (raw.startsWith("$moduleKey list")) return await _handleList(input);
    if (raw.startsWith("$moduleKey done")) return await _handleDone(input);
    if (raw.startsWith("$moduleKey delete")) {
      return performDelete(input, dbService.deleteTask);
    }
    return unknownSubCommand();
  }

  @override
  String get helpText =>
      "**Tasks:**\n- `task add [\"Note\"] @people #tags`\n- `task log [date] [\"Note\"] @people #tags`\n- `task list [@person] [#tag]`";

  Future<String> _handleAdd(String input) async {
    final cmd = ParsedCommand.parse(input, clock: clock);
    return await _processTask(
      cmd.notes,
      cmd.tags,
      cmd.participants,
      isCompleted: false,
    );
  }

  Future<String> _handleLog(String input) async {
    final cmd = ParsedCommand.parse(input, clock: clock);
    return await _processTask(
      cmd.notes,
      cmd.tags,
      cmd.participants,
      isCompleted: true,
      date: cmd.date ?? clock(),
    );
  }

  Future<String> _processTask(
    String notes,
    List<String> tags,
    List<String> people, {
    required bool isCompleted,
    DateTime? date,
  }) async {
    await dbService.addTask(
      notes,
      tags,
      people,
      isCompleted: isCompleted,
      createdAt: date,
    );
    return ResponseFormatter.success(
      isCompleted ? "Task Logged" : "Task Added",
      successCode: isCompleted ? SuccessCode.taskLogged : SuccessCode.taskAdded,
      data: {
        "task": notes.isEmpty ? "(no note)" : notes,
        "status": isCompleted ? "Completed" : "Pending",
        "date": Formatters.formatDate(date ?? clock()),
        "tags": tags.map((t) => '#$t').toList(),
        "with": people.map((p) => '@$p').toList(),
      },
    );
  }

  /// ✅ Fixed: Now handles tag and person filters
  Future<String> _handleList(String input) async {
    final cmd = ParsedCommand.parse(input, clock: clock);
    final tag = cmd.tags.isNotEmpty ? cmd.tags.first : null;
    final part = cmd.participants.isNotEmpty ? cmd.participants.first : null;

    final tasks = await dbService.getTasks(
      includeCompleted: false,
      tag: tag,
      participant: part,
    );
    if (tasks.isEmpty) {
      String msg = "✅ No pending tasks";
      if (tag != null) msg += " with tag #$tag";
      if (part != null) msg += " with @$part";
      return "$msg.";
    }
    final data = tasks
        .map(
          (t) => {
            "id": t.id,
            "task": t.notes.isEmpty ? "(no note)" : t.notes,
            "people": t.displayParticipants,
            "tags": t.displayTags,
          },
        )
        .toList();
    return ResponseFormatter.format("⏳ **Pending Tasks**", {"items": data});
  }

  Future<String> _handleDone(String input) async {
    final id = int.tryParse(
      ParsedCommand.getArgument(input, "$moduleKey done"),
    );
    if (id == null) {
      return ResponseFormatter.error(
        "Provide ID.",
        errorCode: ErrorCode.invalidFormat,
      );
    }
    final count = await dbService.markAsDone(id);
    return count > 0
        ? ResponseFormatter.success(
            "Task Done",
            successCode: SuccessCode.taskCompleted,
            data: {"id": id},
          )
        : ResponseFormatter.error("Not found.", errorCode: ErrorCode.notFound);
  }
}
