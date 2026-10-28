import 'package:flutter/material.dart';

import '../core/widgets/tab_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabPage(
      title: 'Профиль',
      children: [
        ComingSoonCard(
          text: 'Скоро здесь будут твои данные, напоминания и настройки.',
        ),
      ],
    );
  }
}
