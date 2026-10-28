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

class ScreeningScreen extends StatelessWidget {
  const ScreeningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();

    return OnboardingScaffold(
      onBack: () => context.popOrGo(Routes.signup),
      step: 2,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Сначала — о здоровье', style: AppText.title),
          const SizedBox(height: 8),
          Text(
            '9 коротких вопросов, чтобы тренировки были безопасными. Ответы '
            'видишь только ты.',
            style: AppText.subtitle,
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < screeningQuestions.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _QuestionCard(
              key: Key('screening-q$i'),
              text: screeningQuestions[i],
              answer: viewModel.screeningAnswer(i),
              onAnswer: (value) => viewModel.answerScreening(i, value),
            ),
          ],
        ],
      ),
      bottom: [
        Text(
          'Отвечено ${viewModel.screeningAnsweredCount} из '
          '${ScreeningAnswers.questionCount}',
          textAlign: TextAlign.center,
          style: appTextStyle(size: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Дальше',
          onPressed: viewModel.isScreeningComplete
              ? () => context.push(
                    viewModel.isScreeningPassed ? Routes.goal : Routes.stop,
                  )
              : null,
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.text,
    required this.answer,
    required this.onAnswer,
  });

  final String text;
  final bool? answer;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text,
            style: appTextStyle(size: 15, weight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OptionButton(
                  label: 'Нет',
                  selected: answer == false,
                  idleColor: AppColors.background,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  onTap: () => onAnswer(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OptionButton(
                  label: 'Да',
                  selected: answer == true,
                  tone: OptionTone.caution,
                  idleColor: AppColors.background,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  onTap: () => onAnswer(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
