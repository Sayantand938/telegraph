/// Configuration for database connections
class DatabaseConfig {
  /// Name of the finance database file
  final String financeDbName;

  /// Name of the session database file
  final String sessionDbName;

  /// Optional custom database path (for testing or special deployments)
  final String? customDbPath;

  const DatabaseConfig({
    required this.financeDbName,
    required this.sessionDbName,
    this.customDbPath,
  });

  /// Get the full database path for finance database
  String getFinanceDbPath() {
    if (customDbPath != null) {
      return '$customDbPath/$financeDbName';
    }
    return financeDbName;
  }

  /// Get the full database path for session database
  String getSessionDbPath() {
    if (customDbPath != null) {
      return '$customDbPath/$sessionDbName';
    }
    return sessionDbName;
  }

  /// Create a copy with modified fields
  DatabaseConfig copyWith({
    String? financeDbName,
    String? sessionDbName,
    String? customDbPath,
  }) {
    return DatabaseConfig(
      financeDbName: financeDbName ?? this.financeDbName,
      sessionDbName: sessionDbName ?? this.sessionDbName,
      customDbPath: customDbPath ?? this.customDbPath,
    );
  }

  @override
  String toString() {
    return 'DatabaseConfig{financeDbName: $financeDbName, sessionDbName: $sessionDbName, customDbPath: $customDbPath}';
  }
}
