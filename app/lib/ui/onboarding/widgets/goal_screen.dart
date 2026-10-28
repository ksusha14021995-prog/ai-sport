import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/onboarding.dart';
import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/onboarding_scaffold.dart';
import '../../core/widgets/option_button.dart';
import '../../core/widgets/primary_button.dart';
import '../onboarding_labels.dart';
import '../view_models/onboarding_view_model.dart';

class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();
    final answers = viewModel.answers;
    final experiences = Experience.values;

    return OnboardingScaffold(
      onBack: () => context.popOrGo(Routes.screening),
      step: 3,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Цель и возможности', style: AppText.title),
          const SizedBox(height: 20),
          Text('Чего хочешь добиться в первую очередь?', style: AppText.sectionLabel),
          const SizedBox(height: 4),
          Text('Можно выбрать несколько', style: AppText.hint),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final goal in Goal.values)
                OptionButton(
                  key: Key('goal-${goal.name}'),
                  label: goalLabels[goal]!,
                  selected: answers.goals.contains(goal),
                  showCheck: true,
                  horizontalPadding: 14,
                  onTap: () => viewModel.toggleGoal(goal),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Как давно тренируешься регулярно?', style: AppText.sectionLabel),
          const SizedBox(height: 10),
          for (var row = 0; row < experiences.length; row += 2) ...[
            if (row > 0) const SizedBox(height: 8),
            Row(
              children: [
                for (var i = row; i < row + 2; i++) ...[
                  if (i > row) const SizedBox(width: 8),
                  Expanded(
                    child: OptionButton(
                      key: Key('experience-${experiences[i].name}'),
                      label: experienceLabels[experiences[i]]!,
                      selected: answers.experience == experiences[i],
                      onTap: () => viewModel.setExperience(experiences[i]),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Регулярно — это минимум 2 раза в неделю',
            style: appTextStyle(size: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          Text('Сколько дней в неделю?', style: AppText.sectionLabel),
          const SizedBox(height: 10),
          _EqualOptionsRow(
            keyPrefix: 'days',
            options: daysPerWeekOptions,
            selected: answers.daysPerWeek,
            onSelected: viewModel.setDaysPerWeek,
          ),
          const SizedBox(height: 18),
          Text('Сколько минут на тренировку?', style: AppText.sectionLabel),
          const SizedBox(height: 10),
          _EqualOptionsRow(
            keyPrefix: 'minutes',
            options: minutesPerSessionOptions,
            selected: answers.minutesPerSession,
            onSelected: viewModel.setMinutesPerSession,
          ),
        ],
      ),
      bottom: [
        PrimaryButton(
          label: 'Дальше',
          onPressed: viewModel.isGoalStepComplete
              ? () => context.push(Routes.body)
              : null,
        ),
      ],
    );
  }
}

class _EqualOptionsRow extends StatelessWidget {
  const _EqualOptionsRow({
    required this.keyPrefix,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String keyPrefix;
  final Map<int, String> options;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, entry) in options.entries.indexed) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: OptionButton(
              key: Key('$keyPrefix-${entry.key}'),
              label: entry.value,
              selected: selected == entry.key,
              horizontalPadding: 0,
              onTap: () => onSelected(entry.key),
            ),
          ),
        ],
      ],
    );
  }
}
