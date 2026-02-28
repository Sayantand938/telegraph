import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Dead-simple Firestore helper for personal use
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Save a time entry (start/stop/log)
  Future<void> saveTimeEntry(Map<String, dynamic> data) async {
    try {
      await _db.collection('time_entries').add({
        'action': data['action'] ?? 'unknown',
        'note': data['note'],
        'tags': data['tags'] is List ? List<String>.from(data['tags']) : [],
        'start_time': data['start'],
        'end_time': data['end'],
        'status': data['action'] == 'stop' ? 'completed' : 'active',
        'created_at': FieldValue.serverTimestamp(),
      });
      _log('✅ Saved to Firestore: time_entries');
    } catch (e) {
      _log('❌ Firestore error: $e');
    }
  }

  /// Save a task
  Future<void> saveTask(Map<String, dynamic> data) async {
    try {
      await _db.collection('tasks').add({
        'action': data['action'] ?? 'unknown',
        'title': data['title'] ?? data['note'],
        'priority': data['priority'],
        'due': data['due'],
        'status': data['action'] == 'complete' ? 'done' : 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });
      _log('✅ Saved to Firestore: tasks');
    } catch (e) {
      _log('❌ Firestore error: $e');
    }
  }

  /// Save a note
  Future<void> saveNote(Map<String, dynamic> data) async {
    try {
      await _db.collection('notes').add({
        'title': data['title'],
        'content': data['content'] ?? data['note'],
        'tags': data['tags'] is List ? List<String>.from(data['tags']) : [],
        'created_at': FieldValue.serverTimestamp(),
      });
      _log('✅ Saved to Firestore: notes');
    } catch (e) {
      _log('❌ Firestore error: $e');
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('🔥 FirebaseService: $message');
  }
}
