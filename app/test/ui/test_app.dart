import 'package:ai_sport/app.dart';
import 'package:ai_sport/domain/models/onboarding.dart';
import 'package:ai_sport/domain/models/training_plan.dart';
import 'package:ai_sport/ui/core/widgets/primary_button.dart';
import 'package:ai_sport/ui/onboarding/view_models/onboarding_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakePlanBuilder implements PlanBuilder {
  OnboardingAnswers? lastAnswers;

  static const plan = TrainingPlan(
    templateId: 'fake',
    title: 'Ноги и кор',
    level: PlanLevel.beginner,
    weeks: 8,
    sessionsPerWeek: 3,
    minutesPerSession: 30,
    startingExercises: [
      PlanExercise(exerciseId: 'squat', title: 'Приседания', sets: 3, reps: 12),
      PlanExercise(
        exerciseId: 'plank',
        title: 'Планка',
        sets: 3,
        holdSeconds: 30,
      ),
    ],
  );

  @override
  Future<TrainingPlan> build(OnboardingAnswers answers) async {
    lastAnswers = answers;
    return plan;
  }
}

const phoneSmall = Size(360, 640);
const phoneLarge = Size(390, 844);

Future<void> pumpApp(
  WidgetTester tester, {
  required String location,
  Size size = phoneLarge,
  PlanBuilder? planBuilder,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AiSportApp(
      planBuilder: planBuilder ?? FakePlanBuilder(),
      initialLocation: location,
    ),
  );
  await tester.pumpAndSettle();
}

OnboardingViewModel viewModelOf(WidgetTester tester) =>
    tester.element(find.byType(MaterialApp)).read<OnboardingViewModel>();

Finder primaryButtonFinder(String label) =>
    find.widgetWithText(PrimaryButton, label);

bool isEnabled(WidgetTester tester, String label) =>
    tester.widget<PrimaryButton>(primaryButtonFinder(label)).onPressed != null;

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
