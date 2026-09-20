import 'package:intl/intl.dart';

class Formatters {
  static String formatAmount(double? amount) {
    if (amount == null) return '[auto-filled]';
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(amount);
  }

  static String formatAmountWithoutSymbol(double? amount) {
    if (amount == null) return '[auto-filled]';
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0);
    return formatter.format(amount).trim();
  }
}
