import 'base_module.dart';
class TaskModule extends BaseModule {
  
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
        log('   📋 Title: ${data['title'] ?? data['note']}');
        break;
      case 'complete':
      case 'done':
        log('✓ Completing task...', level: 'SUCCESS');
        break;
      default:
        log('Unknown action: $action', level: 'WARNING');
    }
  }
}