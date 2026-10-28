import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Зелёная плашка-подсказка с иконкой слева.
class InfoNote extends StatelessWidget {
  const InfoNote({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: appTextStyle(
                  size: 13,
                  height: 1.45,
                  color: AppColors.onTint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.labelStyle,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.digitsOnly = false,
    this.onChanged,
    this.helperText,
    this.textInputAction = TextInputAction.next,
    this.fieldKey,
  });

  final String label;
  final TextEditingController controller;
  final TextStyle? labelStyle;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final bool digitsOnly;
  final ValueChanged<String>? onChanged;
  final String? helperText;
  final TextInputAction textInputAction;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: labelStyle ?? AppText.fieldLabel),
        const SizedBox(height: 6),
        TextField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          textInputAction: textInputAction,
          inputFormatters:
              digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: appTextStyle(size: 16),
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffix,
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: appTextStyle(size: 12, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}
