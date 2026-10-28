import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

enum OptionTone {
  /// Зелёная подсветка (#CFEBDD + рамка #146C54).
  positive,

  /// Коралловая подсветка — ответ «Да» в скрининге.
  caution,

  /// Сплошная заливка primary — шкала «Насколько было тяжело?».
  solid,

  /// Мятная заливка на тёмном фоне калибровки.
  dark,
}

/// Кнопка-вариант для одиночного и множественного выбора.
class OptionButton extends StatelessWidget {
  const OptionButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.tone = OptionTone.positive,
    this.idleColor = AppColors.card,
    this.minHeight = 44,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w600,
    this.radius,
    this.showCheck = false,
    this.horizontalPadding = 12,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final OptionTone tone;
  final Color idleColor;
  final double minHeight;
  final double fontSize;
  final FontWeight fontWeight;
  final double? radius;
  final bool showCheck;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final (background, border, foreground) = _colors();
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius ?? minHeight / 2),
      side: border,
    );

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: background,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showCheck && selected) ...[
                    Icon(Icons.check_rounded, size: 16, color: foreground),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: appTextStyle(
                        size: fontSize,
                        weight: fontWeight,
                        color: foreground,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  (Color, BorderSide, Color) _colors() {
    const idleBorder = BorderSide(color: AppColors.border);
    if (!selected) {
      return tone == OptionTone.dark
          ? (
              Colors.transparent,
              const BorderSide(color: AppColors.darkBorder),
              AppColors.darkText,
            )
          : (idleColor, idleBorder, AppColors.text);
    }
    return switch (tone) {
      OptionTone.positive => (
          AppColors.chip,
          const BorderSide(color: AppColors.primary, width: 2),
          AppColors.primaryDark,
        ),
      OptionTone.caution => (
          AppColors.coralContainer,
          const BorderSide(color: AppColors.coral, width: 2),
          AppColors.onCoralContainer,
        ),
      OptionTone.solid => (AppColors.primary, BorderSide.none, Colors.white),
      OptionTone.dark => (AppColors.mint, BorderSide.none, AppColors.primaryDark),
    };
  }
}
