import 'base_module.dart';

class TaskModule extends BaseModule {
  TaskModule() : super('task');

  @override
  void handle(Map<String, dynamic> data, DateTime timestamp) {
    incrementCommand();
    // Silent business logic - no terminal output
    // Actual task logic would go here
  }
}