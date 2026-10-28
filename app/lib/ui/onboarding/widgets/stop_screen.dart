import 'package:flutter/material.dart';

import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/onboarding_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surfaces.dart';

class StopScreen extends StatelessWidget {
  const StopScreen({super.key});

  static const _advice = [
    'Покажи врачу свои ответы — их можно сохранить ниже.',
    'Спроси, какие нагрузки тебе подходят.',
    'Если что-то изменилось или ответ был неточным — пройди вопросы заново.',
  ];

  @override
  Widget build(BuildContext context) {
    void backToScreening() => context.popOrGo(Routes.screening);

    return OnboardingScaffold(
      onBack: backToScreening,
      bodyTopPadding: 24,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              size: 34,
              color: AppColors.onWarningContainer,
            ),
          ),
          const SizedBox(height: 20),
          Text('Сначала — к врачу', style: AppText.titleLarge),
          const SizedBox(height: 12),
          Text(
            'По твоим ответам самостоятельные тренировки без контроля '
            'специалиста могут быть небезопасны. Поэтому план мы пока не '
            'составляем.',
            style: appTextStyle(
              size: 16,
              height: 1.5,
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Что можно сделать',
                  style: appTextStyle(size: 15, weight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < _advice.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text('${i + 1}.', style: _adviceStyle),
                      ),
                      Expanded(child: Text(_advice[i], style: _adviceStyle)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Это не диагноз. AI-sport пока подходит только для людей без '
            'медицинских ограничений — мы работаем над тем, чтобы это изменить.',
            style: appTextStyle(
              size: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      bottom: [
        LinkButton(
          label: 'Сохранить ответы для врача',
          // Экспорт ответов появится вместе с бэкендом.
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Сохранение ответов скоро появится')),
          ),
        ),
        const SizedBox(height: 8),
        PrimaryButton(label: 'Изменить ответы', onPressed: backToScreening),
      ],
    );
  }

  static final _adviceStyle = appTextStyle(
    size: 14,
    height: 1.45,
    color: AppColors.textBody,
  );
}
