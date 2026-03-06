// lib/core/utils/formatters.dart
import 'package:intl/intl.dart';

class Formatters {
  static String formatTime(DateTime time) =>
      DateFormat('HH:mm:ss').format(time);
  static String formatShortTime(DateTime time) =>
      DateFormat('HH:mm').format(time);
  static String formatDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);
  static String formatDuration(double minutes) {
    final m = minutes.round();
    final h = m ~/ 60;
    final rem = m % 60;
    return h > 0 ? '${h}h ${rem}m' : '${rem}m';
  }

  static String formatCurrency(double amount, {String symbol = '₹'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
