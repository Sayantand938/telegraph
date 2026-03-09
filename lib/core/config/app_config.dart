import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'database_config.dart';
import 'platform_config.dart';

/// Main application configuration
/// Loads environment-specific settings at startup
class AppConfig {
  /// LLM API configuration
  final String baseUrl;
  final String apiKey;
  final String model;

  /// Database configuration
  final DatabaseConfig database;

  /// Platform-specific configuration
  final PlatformConfig platform;

  /// Application settings
  final bool enableLogging;
  final String environment;

  const AppConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.database,
    required this.platform,
    this.enableLogging = true,
    this.environment = 'development',
  });

  /// Load configuration from environment variables
  /// This should be called during app startup before any services are initialized
  static Future<AppConfig> load({
    required PlatformConfig platformConfig,
  }) async {
    try {
      // Load .env file
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // If .env file doesn't exist, try to load from system environment
      // This allows the app to work in production without a .env file
      if (kIsWeb) {
        // ignore: avoid_print
        print('Warning: Could not load .env file: $e');
        // ignore: avoid_print
        print('Using system environment variables instead.');
      }
    }

    return AppConfig(
      baseUrl: _getEnvVariable('BASE_URL'),
      apiKey: _getEnvVariable('NVIDIA_API_KEY'),
      model: _getEnvVariable('MODEL'),
      database: DatabaseConfig(
        financeDbName: _getEnvVariable(
          'FINANCE_DB_NAME',
          'telegraph_finance.db',
        ),
        sessionDbName: _getEnvVariable('SESSION_DB_NAME', 'telegraph.db'),
        customDbPath: _getEnvVariable('CUSTOM_DB_PATH', ''),
      ),
      platform: platformConfig,
      enableLogging:
          _getEnvVariable('ENABLE_LOGGING', 'true').toLowerCase() == 'true',
      environment: _getEnvVariable('ENVIRONMENT', 'development'),
    );
  }

  /// Get an environment variable with optional default value
  static String _getEnvVariable(String key, [String? defaultValue]) {
    final value = dotenv.env[key];
    if (value != null && value.isNotEmpty) {
      return value;
    }
    if (defaultValue != null) {
      return defaultValue;
    }
    throw ConfigurationException(
      'Missing required environment variable: $key',
      code: 'MISSING_ENV_VAR',
    );
  }

  /// Create a copy of this configuration with modified fields
  /// Useful for testing with overridden values
  AppConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? model,
    DatabaseConfig? database,
    PlatformConfig? platform,
    bool? enableLogging,
    String? environment,
  }) {
    return AppConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      database: database ?? this.database,
      platform: platform ?? this.platform,
      enableLogging: enableLogging ?? this.enableLogging,
      environment: environment ?? this.environment,
    );
  }

  @override
  String toString() {
    return 'AppConfig{'
        'baseUrl: $baseUrl, '
        'apiKey: ${apiKey.substring(0, 10)}..., '
        'model: $model, '
        'database: $database, '
        'platform: $platform, '
        'enableLogging: $enableLogging, '
        'environment: $environment'
        '}';
  }
}

/// Exception thrown when configuration loading fails
class ConfigurationException implements Exception {
  final String message;
  final String? code;

  const ConfigurationException(this.message, {this.code});

  @override
  String toString() => 'ConfigurationException($code): $message';
}
