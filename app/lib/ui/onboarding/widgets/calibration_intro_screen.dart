import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/onboarding_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surfaces.dart';

class CalibrationIntroScreen extends StatelessWidget {
  const CalibrationIntroScreen({super.key});

  static const _tests = [
    (
      'Приседания · 60 секунд',
      'Максимум повторов с правильной техникой. Камера считает и отмечает ошибки.',
    ),
    ('Отжимания · до отказа', 'От пола или с колен — как тебе комфортнее.'),
    ('Планка · на время', 'Держи, пока положение остаётся ровным.'),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      onBack: () => context.popOrGo(Routes.body),
      step: 5,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Проверим твой уровень', style: AppText.title),
          const SizedBox(height: 8),
          Text(
            '3 коротких теста, около 5 минут. По ним план начнётся с твоей '
            'нагрузки, а не с усреднённой.',
            style: AppText.subtitle,
          ),
          const SizedBox(height: 20),
          for (final (index, (title, description)) in _tests.indexed) ...[
            if (index > 0) const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: AppText.number(15, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: appTextStyle(size: 15, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: appTextStyle(
                            size: 13,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          const InfoNote(
            icon: Icons.smartphone_outlined,
            text: 'Поставь телефон на уровне пояса в 2–3 шагах, чтобы в кадр '
                'попадало всё тело. Нужен коврик.',
          ),
        ],
      ),
      bottom: [
        PrimaryButton(
          label: 'Начать проверку',
          onPressed: () => context.push(Routes.calibrationTest),
        ),
      ],
    );
  }
}
