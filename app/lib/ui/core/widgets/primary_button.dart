import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

enum ButtonTone { light, dark }

/// Единая нижняя CTA онбординга: 56 px, радиус 28, на всю ширину.
/// `onPressed == null` — неактивное состояние.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = ButtonTone.light,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final isDark = tone == ButtonTone.dark;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.mint : AppColors.primary,
          foregroundColor: isDark ? AppColors.primaryDark : Colors.white,
          disabledBackgroundColor:
              isDark ? AppColors.darkTrack : AppColors.disabled,
          disabledForegroundColor:
              isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
          shape: const StadiumBorder(),
          textStyle: AppText.button,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Text(label, textAlign: TextAlign.center, maxLines: 1),
      ),
    );
  }
}

/// Текстовая ссылка-кнопка («Войти», «Пропустить…»): минимум 48 px по высоте.
class LinkButton extends StatelessWidget {
  const LinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback? onPressed;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(48, 48),
        shape: const StadiumBorder(),
        textStyle: appTextStyle(size: fontSize, weight: FontWeight.w700),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
