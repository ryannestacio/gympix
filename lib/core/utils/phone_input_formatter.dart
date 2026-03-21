import 'package:flutter/services.dart';

/// Formata telefone BR no padrão: (DD) 99999-9999 / (DD) 9999-9999.
class BrPhoneInputFormatter extends TextInputFormatter {
  const BrPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _onlyDigits(newValue.text);
    final formatted = _formatDigits(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _onlyDigits(String s) => s.replaceAll(RegExp(r'\D'), '');

  static String _formatDigits(String digits) {
    if (digits.isEmpty) return '';
    final d = digits.length > 11 ? digits.substring(0, 11) : digits;
    final dd = d.length >= 2 ? d.substring(0, 2) : d;
    final rest = d.length > 2 ? d.substring(2) : '';

    if (rest.isEmpty) return '($dd';

    // 9 dígitos (celular) ou 8 (fixo)
    final isMobile = rest.length >= 9;
    final first = isMobile
        ? rest.substring(0, rest.length.clamp(0, 5))
        : rest.substring(0, rest.length.clamp(0, 4));
    final second = isMobile
        ? (rest.length > 5 ? rest.substring(5, rest.length.clamp(0, 9)) : '')
        : (rest.length > 4 ? rest.substring(4, rest.length.clamp(0, 8)) : '');

    if (second.isEmpty) return '($dd) $first';
    return '($dd) $first-$second';
  }
}

