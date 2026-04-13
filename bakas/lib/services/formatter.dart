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

class SecurityFormatter {
  static String maskName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return "User";
    
    List<String> parts = fullName.trim().split(' ');
    String firstName = parts[0];
    String lastName = parts.length > 1 ? parts.last : "";
    
    String maskedFirst = "";
    if (firstName.length <= 2) {
      maskedFirst = firstName;
    } else {
      maskedFirst = "${firstName.substring(0, 2)}****${firstName[firstName.length - 1]}";
    }
    
    String maskedLast = "";
    if (lastName.isNotEmpty) {
      maskedLast = " ${lastName[0]}.";
    }
    
    return "$maskedFirst$maskedLast";
  }

  static String maskAccountNumber(String? number) {
    if (number == null || number.isEmpty) return ".... .... ---";
    String lastThree = number.length > 3 
        ? number.substring(number.length - 3) 
        : number;
    return ".... .... $lastThree";
  }
}
