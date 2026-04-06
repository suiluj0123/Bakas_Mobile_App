import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _simpleFormatter = NumberFormat('#,##0.00');

  static String format(dynamic amount) {
    double value = 0.0;
    if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    } else if (amount is num) {
      value = amount.toDouble();
    }

    try {
      return 'PHP ${_simpleFormatter.format(value)}';
    } catch (e) {
      return 'PHP ${value.toStringAsFixed(2)}';
    }
  }

  static String formatJackpot(dynamic amount) {
    double value = 0.0;
    if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    } else if (amount is num) {
      value = amount.toDouble();
    }
    
    try {
      return _simpleFormatter.format(value);
    } catch (e) {
      return value.toStringAsFixed(2);
    }
  }
}
