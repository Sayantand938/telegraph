import 'base_module.dart';

class TimeModule extends BaseModule {
  TimeModule() : super('time');

  @override
  void handle(Map<String, dynamic> data, DateTime timestamp) {
    incrementCommand();
    // Silent business logic - no terminal output
    // Actual timer logic would go here
  }
}