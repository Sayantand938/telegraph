// lib/services/modules/time_module/time_module.dart
import '../base_module.dart';
import '../../database/database_helper.dart';
import 'commands/start_command.dart';
import 'commands/stop_command.dart';
import 'commands/add_command.dart';
import 'commands/status_command.dart';
import 'commands/list_command.dart';

/// Time Module with SQLite persistence
class TimeModule extends BaseModule {
  TimeModule() : super('time');

  final DatabaseHelper _db = DatabaseHelper();

  late final StartCommand _startCommand;
  late final StopCommand _stopCommand;
  late final AddCommand _addCommand;
  late final StatusCommand _statusCommand;
  late final ListCommand _listCommand;

  @override
  void init() {
    super.init();
    _startCommand = StartCommand(_db);
    _stopCommand = StopCommand(_db);
    _addCommand = AddCommand(_db);
    _statusCommand = StatusCommand(_db);
    _listCommand = ListCommand(_db);
  }

  @override
  Future<String?> handle(Map<String, dynamic> data, DateTime timestamp) async {
    incrementCommand();
    final action = data['action'] as String?;

    switch (action) {
      case 'start':
        return await _startCommand.execute(data, timestamp);
      case 'stop':
        return await _stopCommand.execute(data, timestamp);
      case 'add':
        return await _addCommand.execute(data, timestamp);
      case 'status':
        return await _statusCommand.execute();
      case 'list':
        return await _listCommand.execute();
      default:
        return '❌ Unknown action: "$action". Try: start, stop, add, status, list';
    }
  }

  @override
  Map<String, dynamic> getStats() {
    final baseStats = super.getStats();
    return {...baseStats, 'storage': 'SQLite'};
  }
}
