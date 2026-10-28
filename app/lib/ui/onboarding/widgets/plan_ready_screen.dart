import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/training_plan.dart';
import '../../../routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/onboarding_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surfaces.dart';
import '../onboarding_labels.dart';
import '../view_models/onboarding_view_model.dart';

/// Макет Safety.dc.html — «Твой план готов».
class PlanReadyScreen extends StatefulWidget {
  const PlanReadyScreen({super.key});

  @override
  State<PlanReadyScreen> createState() => _PlanReadyScreenState();
}

class _PlanReadyScreenState extends State<PlanReadyScreen> {
  @override
  void initState() {
    super.initState();
    // Ответы могли поменяться после возврата назад — пересобираем план при каждом входе.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OnboardingViewModel>().buildPlan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();
    final plan = viewModel.plan;
    final isReady =
        plan != null && !viewModel.isBuildingPlan && viewModel.planError == null;

    return OnboardingScaffold(
      body: switch ((viewModel.isBuildingPlan, viewModel.planError, plan)) {
        (true, _, _) || (false, null, null) => const _PlanLoading(),
        (false, final Object _, _) => _PlanError(onRetry: viewModel.buildPlan),
        (false, null, final TrainingPlan plan) => _PlanSummary(
            plan: plan,
            goalsLabel: viewModel.answers.goals
                .map((goal) => goalLabels[goal]!)
                .join(', '),
          ),
      },
      bottom: [
        PrimaryButton(
          label: 'К первой тренировке',
          onPressed: isReady ? () => context.go(Routes.home) : null,
        ),
      ],
    );
  }
}

class _PlanLoading extends StatelessWidget {
  const _PlanLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('Собираем план…', style: AppText.subtitle),
        ],
      ),
    );
  }
}

class _PlanError extends StatelessWidget {
  const _PlanError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Не получилось собрать план', style: AppText.title),
        const SizedBox(height: 8),
        Text(
          'Попробуй ещё раз. Если не поможет — вернись и проверь ответы.',
          style: AppText.subtitle,
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onRetry,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            minimumSize: const Size(140, 48),
            shape: const StadiumBorder(),
          ),
          child: const Text('Повторить'),
        ),
      ],
    );
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plan, required this.goalsLabel});

  final TrainingPlan plan;
  final String goalsLabel;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Цель', goalsLabel),
      ('Стартовый уровень', planLevelLabels[plan.level]!),
      for (final exercise in plan.startingExercises)
        (exercise.title, _formatNorm(exercise)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.check_rounded, size: 30, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        Text('Твой план готов', style: AppText.title),
        const SizedBox(height: 8),
        Text(
          'Собрали по твоим ответам и результатам проверки.',
          style: AppText.subtitle,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _StatTile(value: '${plan.weeks}', label: 'недель')),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                value: '${plan.sessionsPerWeek}×',
                label: 'в неделю',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                value: '${plan.minutesPerSession}',
                label: 'минут',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final (index, (label, value)) in rows.indexed) ...[
                if (index > 0) const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: appTextStyle(
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          value,
                          textAlign: TextAlign.right,
                          style: appTextStyle(
                            size: 15,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const InfoNote(
          icon: Icons.autorenew_rounded,
          text: 'Через 2 недели повторим проверку и обновим нагрузку.',
        ),
      ],
    );
  }

  static String _formatNorm(PlanExercise exercise) {
    final reps = exercise.reps;
    return reps != null
        ? '${exercise.sets} × $reps'
        : '${exercise.sets} × ${exercise.holdSeconds} сек';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 16,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.number(20)),
          const SizedBox(height: 2),
          Text(
            label,
            style: appTextStyle(size: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
