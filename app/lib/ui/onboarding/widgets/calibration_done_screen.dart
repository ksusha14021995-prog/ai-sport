import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/onboarding_scaffold.dart';
import '../../core/widgets/option_button.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surfaces.dart';
import '../onboarding_labels.dart';
import '../view_models/onboarding_view_model.dart';

class CalibrationDoneScreen extends StatelessWidget {
  const CalibrationDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();
    final difficulty = viewModel.perceivedDifficulty;

    return OnboardingScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Проверка пройдена', style: AppText.title),
          const SizedBox(height: 8),
          Text(
            'Вот твоя точка старта. Через 2 недели повторим и сравним.',
            style: AppText.subtitle,
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                _ResultRow(
                  title: 'Приседания за 60 сек',
                  note: 'Без ошибок техники',
                  value: '${viewModel.squatReps ?? 0}',
                ),
                const Divider(),
                _ResultRow(
                  title: 'Отжимания',
                  note: pushupVariantLabels[viewModel.pushupVariant]!
                      .toLowerCase(),
                  value: '${viewModel.pushupReps ?? 0}',
                ),
                const Divider(),
                _ResultRow(
                  title: 'Планка',
                  note: 'Без ошибок положения',
                  value: formatSeconds(viewModel.plankSeconds ?? 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Насколько было тяжело?', style: AppText.sectionLabel),
          const SizedBox(height: 4),
          Text('1 — совсем легко, 10 — на пределе', style: AppText.hint),
          const SizedBox(height: 10),
          for (final rowStart in const [1, 6]) ...[
            if (rowStart > 1) const SizedBox(height: 8),
            Row(
              children: [
                for (var value = rowStart; value < rowStart + 5; value++) ...[
                  if (value > rowStart) const SizedBox(width: 8),
                  Expanded(
                    child: OptionButton(
                      key: Key('difficulty-$value'),
                      label: '$value',
                      selected: difficulty == value,
                      tone: OptionTone.solid,
                      minHeight: 48,
                      radius: 16,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      horizontalPadding: 0,
                      onTap: () => viewModel.setPerceivedDifficulty(value),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
      bottom: [
        PrimaryButton(
          label: 'Составить план',
          onPressed: difficulty != null
              ? () => context.push(Routes.planReady)
              : null,
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.title,
    required this.note,
    required this.value,
  });

  final String title;
  final String note;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: appTextStyle(size: 15, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: appTextStyle(
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: AppText.number(22)),
        ],
      ),
    );
  }
}
