import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Каркас экрана онбординга: шапка (назад + прогресс) закреплена сверху,
/// контент прокручивается, нижние кнопки закреплены снизу.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.body,
    required this.bottom,
    this.onBack,
    this.step,
    this.totalSteps = 5,
    this.backgroundColor = AppColors.background,
    this.foregroundColor = AppColors.text,
    this.bodyTopPadding = 20,
    this.horizontalPadding = 24,
  });

  final Widget body;
  final List<Widget> bottom;
  final VoidCallback? onBack;
  final int? step;
  final int totalSteps;
  final Color backgroundColor;
  final Color foregroundColor;
  final double bodyTopPadding;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final hasHeader = onBack != null || step != null;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasHeader)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding - 12,
                  16,
                  horizontalPadding,
                  0,
                ),
                child: Row(
                  children: [
                    if (onBack != null)
                      BackIconButton(onPressed: onBack!, color: foregroundColor)
                    else
                      const SizedBox(width: 12),
                    if (step != null)
                      Expanded(
                        child: StepProgress(current: step!, total: totalSteps),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  hasHeader ? bodyTopPadding : 40,
                  horizontalPadding,
                  8,
                ),
                child: body,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BackIconButton extends StatelessWidget {
  const BackIconButton({
    super.key,
    required this.onPressed,
    this.color = AppColors.text,
    this.icon = Icons.chevron_left_rounded,
    this.tooltip = 'Назад',
  });

  final VoidCallback onPressed;
  final Color color;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: icon == Icons.chevron_left_rounded ? 30 : 24),
      color: color,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      padding: EdgeInsets.zero,
    );
  }
}

class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.current,
    required this.total,
    this.activeColor = AppColors.primary,
    this.trackColor = AppColors.border,
  });

  final int current;
  final int total;
  final Color activeColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Шаг $current из $total',
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i < current ? activeColor : trackColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
