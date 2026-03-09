import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/services/database/finance_database.dart';
import 'package:telegraph/services/database/session_database.dart';
import 'package:telegraph/services/repositories/finance_repository_impl.dart';
import 'package:telegraph/services/repositories/session_repository_impl.dart';

/// Helper for integration tests that need a real database.
/// Uses in-memory SQLite for fast, isolated tests.
class DatabaseTestHelper {
  static Database? _db;
  static FinanceDatabase? _financeDb;
  static SessionDatabase? _sessionDb;

  /// Initialize in-memory database and set up the global factory.
  static Future<void> initialize() async {
    if (_db != null) {
      await cleanup();
    }

    // Initialize FFI for desktop/mobile
    sqfliteFfiInit();

    // Set the global database factory to use FFI
    databaseFactory = databaseFactoryFfi;

    // Create in-memory database
    final db = await databaseFactory.openDatabase(
      ':memory:',
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          // Finance database schema
          await db.execute('''
            CREATE TABLE finance_transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              type TEXT NOT NULL,
              amount REAL NOT NULL,
              transaction_time TEXT NOT NULL,
              note TEXT
            )
          ''');

          // Session database schema
          await db.execute('''
            CREATE TABLE sessions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              start_time TEXT NOT NULL,
              end_time TEXT,
              notes TEXT
            )
          ''');
        },
      ),
    );

    _db = db;

    // Create database instances with injected connection
    _financeDb = FinanceDatabase.injected(db, 'telegraph_finance.db');
    _sessionDb = SessionDatabase.injected(db, 'telegraph.db');
  }

  /// Get a FinanceRepository backed by the shared in-memory database.
  static Future<FinanceRepository> getFinanceRepository() async {
    if (_financeDb == null) {
      throw StateError(
        'Database not initialized. Call DatabaseTestHelper.initialize() first.',
      );
    }
    return FinanceRepository(_financeDb!);
  }

  /// Get a SessionRepository backed by the shared in-memory database.
  static Future<SessionRepository> getSessionRepository() async {
    if (_sessionDb == null) {
      throw StateError(
        'Database not initialized. Call DatabaseTestHelper.initialize() first.',
      );
    }
    return SessionRepository(_sessionDb!);
  }

  /// Clear all data from both tables (for use in tearDown)
  static Future<void> clearAllData() async {
    if (_db != null) {
      await _db!.delete('finance_transactions');
      await _db!.delete('sessions');
    }
  }

  /// Clean up the in-memory database
  static Future<void> cleanup() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _financeDb = null;
      _sessionDb = null;
    }
  }
}
