/// Configuration for platform-specific behavior
class PlatformConfig {
  /// Whether to use FFI (Foreign Function Interface) for SQLite on desktop platforms
  final bool useFfi;

  /// Optional custom database path override
  final String? customDbPath;

  /// Whether to enable debug logging for platform-specific code
  final bool enableDebugLogging;

  const PlatformConfig({
    required this.useFfi,
    this.customDbPath,
    this.enableDebugLogging = false,
  });

  /// Create platform config based on current runtime platform
  factory PlatformConfig.detect() {
    // Note: We can't use dart:io Platform directly in this factory
    // because it might be called from web context. The actual detection
    // should happen in AppConfig.load() where we have proper context.

    return PlatformConfig(
      useFfi: false, // Default, will be overridden in AppConfig.load()
      enableDebugLogging: false,
    );
  }

  /// Create a copy with modified fields
  PlatformConfig copyWith({
    bool? useFfi,
    String? customDbPath,
    bool? enableDebugLogging,
  }) {
    return PlatformConfig(
      useFfi: useFfi ?? this.useFfi,
      customDbPath: customDbPath ?? this.customDbPath,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
    );
  }

  @override
  String toString() {
    return 'PlatformConfig{useFfi: $useFfi, customDbPath: $customDbPath, enableDebugLogging: $enableDebugLogging}';
  }
}
