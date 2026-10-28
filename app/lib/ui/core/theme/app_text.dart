import 'package:flutter/painting.dart';

import 'app_colors.dart';

abstract final class AppFonts {
  static const body = 'Manrope';
  static const heading = 'Unbounded';
}

/// Шрифты подключены как variable TTF: насыщенность задаётся осью `wght`,
/// поэтому вместе с [FontWeight] всегда выставляем [FontVariation].
TextStyle appTextStyle({
  required double size,
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.text,
  double? height,
  double? letterSpacing,
  String family = AppFonts.body,
}) {
  return TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

abstract final class AppText {
  static final display = appTextStyle(
    family: AppFonts.heading,
    size: 28,
    weight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.4,
  );
  static final title = appTextStyle(
    family: AppFonts.heading,
    size: 24,
    weight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.3,
  );
  static final titleLarge = appTextStyle(
    family: AppFonts.heading,
    size: 26,
    weight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.3,
  );
  static TextStyle number(double size, {Color color = AppColors.text}) =>
      appTextStyle(
        family: AppFonts.heading,
        size: size,
        weight: FontWeight.w600,
        color: color,
        height: 1.1,
      );

  static final lead = appTextStyle(
    size: 16,
    height: 1.5,
    color: AppColors.textSecondary,
  );
  static final subtitle = appTextStyle(
    size: 14,
    height: 1.5,
    color: AppColors.textSecondary,
  );
  static final sectionLabel = appTextStyle(size: 15, weight: FontWeight.w700);
  static final hint = appTextStyle(size: 13, color: AppColors.textSecondary);
  static final fieldLabel = appTextStyle(
    size: 13,
    weight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
  static final button = appTextStyle(size: 16, weight: FontWeight.w700);
}
