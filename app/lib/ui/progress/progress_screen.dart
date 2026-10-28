import 'package:flutter/material.dart';

import '../core/widgets/tab_page.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabPage(
      title: 'Прогресс',
      children: [
        ComingSoonCard(
          text: 'После первых тренировок здесь будут повторы, оценки техники '
              'и серия без пропусков.',
        ),
      ],
    );
  }
}
