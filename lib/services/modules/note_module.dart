import 'base_module.dart';
class NoteModule extends BaseModule {
  
  NoteModule() : super('note');

  @override
  void handle(Map<String, dynamic> data, DateTime timestamp) {
    incrementCommand();
    log('📥 Note received', level: 'INFO');
    log('   📝 Title: ${data['title'] ?? 'Untitled'}');
    log('🗒️ Note processed (local mode)', level: 'SUCCESS');
  }
}