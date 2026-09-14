import 'package:intl/intl.dart';

final _amountFormat = NumberFormat('#,##0.00');

/// Formats a monetary value with thousand separators, e.g. 1234567.5 -> "1,234,567.50".
String formatAmount(num value) => _amountFormat.format(value);
