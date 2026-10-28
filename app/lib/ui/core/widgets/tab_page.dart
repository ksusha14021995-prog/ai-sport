import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'surfaces.dart';

/// Общий каркас вкладки нижней навигации: заголовок + прокручиваемый контент.
class TabPage extends StatelessWidget {
  const TabPage({
    super.key,
    required this.title,
    required this.children,
    this.overline,
  });

  final String title;
  final String? overline;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        children: [
          if (overline != null) ...[
            Text(
              overline!,
              style: appTextStyle(size: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
          ],
          Text(title, style: AppText.title),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class ComingSoonCard extends StatelessWidget {
  const ComingSoonCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Text(
        text,
        style: appTextStyle(
          size: 14,
          height: 1.5,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
