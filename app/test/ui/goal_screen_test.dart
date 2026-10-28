import 'package:ai_sport/domain/models/onboarding.dart';
import 'package:ai_sport/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets('goals are multi-select and toggle off on second tap',
      (tester) async {
    await pumpApp(tester, location: Routes.goal);
    final viewModel = viewModelOf(tester);

    await tapVisible(tester, find.byKey(const Key('goal-loseWeight')));
    await tapVisible(tester, find.byKey(const Key('goal-endurance')));
    expect(viewModel.answers.goals, {Goal.loseWeight, Goal.endurance});

    await tapVisible(tester, find.byKey(const Key('goal-loseWeight')));
    expect(viewModel.answers.goals, {Goal.endurance});
  });

  testWidgets('experience, days and minutes are single-select', (tester) async {
    await pumpApp(tester, location: Routes.goal);
    final viewModel = viewModelOf(tester);

    await tapVisible(tester, find.byKey(const Key('experience-none')));
    await tapVisible(tester, find.byKey(const Key('experience-over2Years')));
    await tapVisible(tester, find.byKey(const Key('days-3')));
    await tapVisible(tester, find.byKey(const Key('days-5')));
    expect(viewModel.answers.experience, Experience.over2Years);
    expect(viewModel.answers.daysPerWeek, 5);
  });

  testWidgets('CTA enabled only when goal, experience, days and minutes set',
      (tester) async {
    await pumpApp(tester, location: Routes.goal);
    expect(isEnabled(tester, 'Дальше'), isFalse);

    await tapVisible(tester, find.byKey(const Key('goal-tone')));
    await tapVisible(tester, find.byKey(const Key('experience-under6Months')));
    await tapVisible(tester, find.byKey(const Key('days-2')));
    expect(isEnabled(tester, 'Дальше'), isFalse);

    await tapVisible(tester, find.byKey(const Key('minutes-45')));
    expect(isEnabled(tester, 'Дальше'), isTrue);

    await tapVisible(tester, find.byKey(const Key('goal-tone')));
    expect(isEnabled(tester, 'Дальше'), isFalse);
  });
}
