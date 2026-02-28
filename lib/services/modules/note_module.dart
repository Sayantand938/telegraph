import 'base_module.dart';
import '../firebase_service.dart';

class NoteModule extends BaseModule {
  final FirebaseService _firebase = FirebaseService();

  NoteModule() : super('note');

  @override
  void handle(Map<String, dynamic> data, DateTime timestamp) {
    incrementCommand();

    log('📥 Note received', level: 'INFO');

    _firebase.saveNote({
      'title': data['title'],
      'content': data['content'] ?? data['note'],
      'tags': data['tags'],
    });

    log('🗒️ Saved to Firestore', level: 'SUCCESS');
  }
}
