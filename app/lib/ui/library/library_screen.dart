import 'package:flutter/material.dart';

import '../core/widgets/tab_page.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabPage(
      title: 'Упражнения',
      children: [
        ComingSoonCard(
          text: 'Скоро здесь появится библиотека упражнений с подсказками '
              'по технике.',
        ),
      ],
    );
  }
}
