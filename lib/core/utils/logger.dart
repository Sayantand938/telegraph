// lib/core/utils/logger.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class Logger {
  static bool _enabled = kDebugMode;
  static File? _logFile;
  static final _timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  static Future<void> initFileLog(String directoryPath) async {
    if (directoryPath.isEmpty || directoryPath == ':memory:') return;

    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final path = '${dir.path}/telegraph_debug.log';
      _logFile = File(path);

      if (await _logFile!.exists()) {
        final size = await _logFile!.length();
        if (size > 5 * 1024 * 1024) {
          // 5MB limit
          await _logFile!.writeAsString('');
        }
      }

      log('--- Log Session Started ---', tag: 'SYSTEM');
    } catch (e) {
      debugPrint('Failed to initialize file logger: $e');
    }
  }

  static void setEnabled(bool enabled) => _enabled = enabled;

  static void _write(String level, String tag, String msg, {Object? err}) {
    final timestamp = _timeFormat.format(DateTime.now());
    final prefix = tag.isNotEmpty ? '[$tag]' : '';
    final logLine =
        '$timestamp $level $prefix $msg ${err != null ? "\nError: $err" : ""}\n';

    if (_enabled) {
      debugPrint(logLine.trim());
    }

    if (_logFile != null) {
      try {
        _logFile!.writeAsStringSync(logLine, mode: FileMode.append);
      } catch (e) {
        // Fallback if file becomes unwritable
      }
    }
  }

  static void log(String msg, {String? tag}) => _write('INFO', tag ?? '', msg);

  static void error(String msg, {String? tag, Object? err, StackTrace? stack}) {
    _write('ERROR', tag ?? '', msg, err: err);
    if (stack != null && (_enabled || _logFile != null)) {
      final stackMsg = 'Stack Trace:\n$stack\n';
      if (_enabled) debugPrint(stackMsg);
      try {
        _logFile?.writeAsStringSync(stackMsg, mode: FileMode.append);
      } catch (_) {}
    }
  }

  static void warn(String msg, {String? tag}) => _write('WARN', tag ?? '', msg);
  static void db(String msg) => log(msg, tag: 'DB');
  static void cmd(String msg) => log(msg, tag: 'CMD');
  static void ui(String msg) => log(msg, tag: 'UI');
  static void init(String msg) => log(msg, tag: 'INIT');

  static String get logPath => _logFile?.path ?? 'Not Initialized';
}
