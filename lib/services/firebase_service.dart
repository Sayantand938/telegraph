import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Mock Firebase service for local testing - NO external dependencies
/// Same interface as original - easy to swap back later
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Local in-memory storage (resets on app restart)
  final List<Map<String, dynamic>> _timeEntries = [];
  final List<Map<String, dynamic>> _tasks = [];
  final List<Map<String, dynamic>> _notes = [];

  /// Save a time entry (mock)
  Future<void> saveTimeEntry(Map<String, dynamic> data) async {
    final entry = {
      'action': data['action'] ?? 'unknown',
      'note': data['note'],
      'tags': _safeStringList(data['tags']),
      'start_time': data['start'],
      'end_time': data['end'],
      'status': data['action'] == 'stop' ? 'completed' : 'active',
      'created_at': DateTime.now().toIso8601String(),
      'id': DateTime.now().millisecondsSinceEpoch, // simple mock ID
    };
    _timeEntries.add(entry);
    _log('🕐 [MOCK] Time entry saved: ${entry['id']}');
    _log('   └─ ${jsonEncode(entry)}');
  }

  /// Save a task (mock)
  Future<void> saveTask(Map<String, dynamic> data) async {
    final task = {
      'action': data['action'] ?? 'unknown',
      'title': data['title'] ?? data['note'],
      'priority': data['priority'],
      'due': data['due'],
      'status': data['action'] == 'complete' ? 'done' : 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'id': DateTime.now().millisecondsSinceEpoch,
    };
    _tasks.add(task);
    _log('✅ [MOCK] Task saved: ${task['title']}');
  }

  /// Save a note (mock)
  Future<void> saveNote(Map<String, dynamic> data) async {
    final note = {
      'title': data['title'],
      'content': data['content'] ?? data['note'],
      'tags': _safeStringList(data['tags']),
      'created_at': DateTime.now().toIso8601String(),
      'id': DateTime.now().millisecondsSinceEpoch,
    };
    _notes.add(note);
    _log('🗒️ [MOCK] Note saved: ${note['title'] ?? 'Untitled'}');
  }

  // Helper: Ensure tags is List<String>
  List<String> _safeStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    if (value is String) return [value];
    return [];
  }

  // Helper: View mock data (for debugging)
  List<Map<String, dynamic>> getMockData(String collection) {
    switch (collection) {
      case 'time_entries': return List.unmodifiable(_timeEntries);
      case 'tasks': return List.unmodifiable(_tasks);
      case 'notes': return List.unmodifiable(_notes);
      default: return [];
    }
  }

  // Helper: Get counts
  Map<String, int> getStats() {
    return {
      'time_entries': _timeEntries.length,
      'tasks': _tasks.length,
      'notes': _notes.length,
    };
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('🧪 MockFirebase: $message');
  }

  // Clear all mock data (for testing)
  void clearAll() {
    _timeEntries.clear();
    _tasks.clear();
    _notes.clear();
    _log('🗑️ Mock data cleared');
  }
}