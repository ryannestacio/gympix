import 'package:flutter/material.dart';

/// Cores semânticas (status) que não existem no ColorScheme padrão.
class AppThemeExtensions extends ThemeExtension<AppThemeExtensions> {
  const AppThemeExtensions({
    required this.success,
    required this.warning,
    required this.info,
  });

  final Color success;
  final Color warning;
  final Color info;

  static AppThemeExtensions of(BuildContext context) {
    return Theme.of(context).extension<AppThemeExtensions>()!;
  }

  @override
  AppThemeExtensions copyWith({Color? success, Color? warning, Color? info}) {
    return AppThemeExtensions(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  AppThemeExtensions lerp(ThemeExtension<AppThemeExtensions>? other, double t) {
    if (other is! AppThemeExtensions) return this;
    return AppThemeExtensions(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }

  static const AppThemeExtensions light = AppThemeExtensions(
    success: Color(0xFF22C55E),
    warning: Color(0xFFF97316),
    info: Color(0xFF3B82F6),
  );

  static const AppThemeExtensions dark = AppThemeExtensions(
    success: Color(0xFF3DDC97),
    warning: Color(0xFFFFB020),
    info: Color(0xFF60A5FA),
  );
}
