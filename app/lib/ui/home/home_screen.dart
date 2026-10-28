import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../routing/routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/widgets/surfaces.dart';
import '../core/widgets/tab_page.dart';
import '../onboarding/view_models/onboarding_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<OnboardingViewModel>().plan;
    final firstExercise = plan?.startingExercises.firstOrNull;

    return TabPage(
      overline: plan != null ? 'Неделя 1 из ${plan.weeks}' : null,
      title: 'Привет!',
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.mint,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Сегодня',
                    style: appTextStyle(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.chip,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                plan?.title ?? 'Первая тренировка',
                style: appTextStyle(
                  family: AppFonts.heading,
                  size: 22,
                  weight: FontWeight.w600,
                  height: 1.2,
                  color: Colors.white,
                ),
              ),
              if (plan != null) ...[
                const SizedBox(height: 10),
                Text(
                  '${plan.minutesPerSession} мин · '
                  '${plan.startingExercises.length} упражнений',
                  style: appTextStyle(size: 14, color: const Color(0xFFE2F4EA)),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => context.push(
                    Routes.camera(firstExercise?.exerciseId ?? 'squat'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    shape: const StadiumBorder(),
                    textStyle: AppText.button,
                  ),
                  child: const Text('Начать тренировку'),
                ),
              ),
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
}
