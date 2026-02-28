import 'base_module.dart';
import '../firebase_service.dart';

class TimeModule extends BaseModule {
  final FirebaseService _firebase = FirebaseService();

  TimeModule() : super('time');

  @override
  void handle(Map<String, dynamic> data, DateTime timestamp) {
    incrementCommand();

    final action = data['action'] as String?;

    log('📥 Received: action=$action', level: 'INFO');

    switch (action) {
      case 'start':
        _handleStart(data, timestamp);
        break;
      case 'stop':
        _handleStop(data, timestamp);
        break;
      case 'add':
        _handleAdd(data, timestamp);
        break;
      case 'log':
        _handleLog(data, timestamp);
        break;
      default:
        log('Unknown action: $action', level: 'WARNING');
    }
  }

  void _handleStart(Map<String, dynamic> data, DateTime timestamp) {
    log('▶️ Starting timer...', level: 'SUCCESS');
    if (data['note'] != null) log('   📝 ${data['note']}');
    if (data['tags'] is List)
      log('   🏷️ ${(data['tags'] as List).join(', ')}');

    // Save to Firestore
    _firebase.saveTimeEntry({
      'action': 'start',
      'note': data['note'],
      'tags': data['tags'],
      'start_time': data['start'] ?? timestamp.toIso8601String(),
    });
  }

  void _handleStop(Map<String, dynamic> data, DateTime timestamp) {
    log('⏹️ Stopping timer...', level: 'SUCCESS');

    _firebase.saveTimeEntry({
      'action': 'stop',
      'end_time': data['end'] ?? timestamp.toIso8601String(),
    });
  }

  void _handleAdd(Map<String, dynamic> data, DateTime timestamp) {
    log('➕ Adding time entry...', level: 'SUCCESS');

    _firebase.saveTimeEntry({
      'action': 'add',
      'note': data['note'],
      'tags': data['tags'],
      'start_time': data['start'],
      'end_time': data['end'],
    });
  }

  void _handleLog(Map<String, dynamic> data, DateTime timestamp) {
    log('📊 Logging time...', level: 'SUCCESS');

    _firebase.saveTimeEntry({
      'action': 'log',
      'note': data['note'],
      'start_time': data['start'],
      'end_time': data['end'],
    });
  }
}
