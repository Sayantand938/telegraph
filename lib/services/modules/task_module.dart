import 'base_module.dart';
import '../firebase_service.dart';

class TaskModule extends BaseModule {
  final FirebaseService _firebase = FirebaseService();

  TaskModule() : super('task');

  @override
  void handle(Map<String, dynamic> data, DateTime timestamp) {
    incrementCommand();
    final action = data['action'] as String?;

    log('📥 Task: $action', level: 'INFO');

    switch (action) {
      case 'add':
      case 'create':
        log('✅ Creating task...', level: 'SUCCESS');
        _firebase.saveTask({
          'action': 'add',
          'title': data['title'] ?? data['note'],
          'priority': data['priority'],
          'due': data['due'],
        });
        break;
      case 'complete':
      case 'done':
        log('✓ Completing task...', level: 'SUCCESS');
        _firebase.saveTask({
          'action': 'complete',
          'title': data['title'] ?? data['note'],
        });
        break;
      default:
        log('Unknown action: $action', level: 'WARNING');
    }
  }
}
