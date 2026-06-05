import 'package:intl/intl.dart';

/// Formateadores de valores para AndesPay
class AppFormatters {
  AppFormatters._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'es_EC',
    symbol: '\$',
    customPattern: '\$#,##0.00',
    decimalDigits: 2,
  );

  static final _dateFormat = DateFormat('dd MMM yyyy', 'es');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'es');
  static final _shortDateFormat = DateFormat('dd/MM/yyyy', 'es');

  /// Formatea un monto como moneda: $1,234.56
  static String currency(double amount) => _currencyFormat.format(amount);

  /// Formatea solo el monto sin símbolo de moneda
  static String amount(double amount) =>
      NumberFormat('#,##0.00', 'es').format(amount);

  /// Fecha larga: 04 jun. 2025
  static String date(DateTime date) => _dateFormat.format(date);

  /// Fecha con hora: 04 jun. 2025, 14:30
  static String dateTime(DateTime date) => _dateTimeFormat.format(date);

  /// Fecha corta: 04/06/2025
  static String shortDate(DateTime date) => _shortDateFormat.format(date);

  /// Fecha relativa: "Hoy", "Ayer", o la fecha formateada
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hoy';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Ayer';
    return AppFormatters.date(date);
  }

  /// Número de cuenta con guiones: 1234-5678-90
  static String accountNumber(String number) {
    if (number.length != 10) return number;
    return '${number.substring(0, 4)}-${number.substring(4, 8)}-${number.substring(8)}';
  }
}
