import 'base_module.dart';
class TimeModule extends BaseModule {
  
  TimeModule() : super('time');

  @override
  void handle(Map<String, dynamic> data, DateTime timestamp) {
    incrementCommand();
    final action = data['action'] as String?;
    log('📥 Received: action=$action', level: 'INFO');

    switch (action) {
      case 'start':
        log('▶️ Starting timer...', level: 'SUCCESS');
        if (data['note'] != null) log('   📝 ${data['note']}');
        break;
      case 'stop':
        log('⏹️ Stopping timer...', level: 'SUCCESS');
        break;
      case 'add':
        log('➕ Adding time entry...', level: 'SUCCESS');
        break;
      case 'log':
        log('📊 Logging time...', level: 'SUCCESS');
        break;
      default:
        log('Unknown action: $action', level: 'WARNING');
    }
  }
}