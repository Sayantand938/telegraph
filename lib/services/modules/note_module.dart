import 'base_module.dart';

class NoteModule extends BaseModule {
  NoteModule() : super('note');

  @override
  void handle(Map<String, dynamic> data, DateTime timestamp) {
    incrementCommand();
    // Silent business logic - no terminal output
    // Actual note logic would go here
  }
}