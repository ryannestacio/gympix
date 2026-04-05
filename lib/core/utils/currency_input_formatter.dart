import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _brlFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

class BrlCurrencyInputFormatter extends TextInputFormatter {
  const BrlCurrencyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return TextEditingValue.empty;
    }

    final value = int.parse(digits) / 100;
    final formatted = _brlFormatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String formatBrl(double value) => _brlFormatter.format(value);

double? parseBrlCurrency(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  return int.parse(digits) / 100;
}
