import 'package:flutter/services.dart';

final RegExp _firstLetterRegex = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]');

String forceFirstLetterUppercase(String value) {
  if (value.isEmpty) return value;

  final match = _firstLetterRegex.firstMatch(value);
  if (match == null) return value;

  final start = match.start;
  final letter = value[start];
  final upper = letter.toUpperCase();
  if (upper == letter) return value;

  return value.replaceRange(start, start + 1, upper);
}

class FirstLetterUppercaseFormatter extends TextInputFormatter {
  const FirstLetterUppercaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = forceFirstLetterUppercase(newValue.text);
    if (formatted == newValue.text) return newValue;

    return newValue.copyWith(
      text: formatted,
      selection: newValue.selection,
      composing: newValue.composing,
    );
  }
}
