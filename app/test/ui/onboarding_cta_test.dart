import 'package:ai_sport/domain/models/onboarding.dart';
import 'package:ai_sport/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets('signup CTA needs valid email, 8+ char password and consent',
      (tester) async {
    await pumpApp(tester, location: Routes.signup);
    expect(isEnabled(tester, 'Дальше'), isFalse);

    await tester.enterText(find.byKey(const Key('signup-email')), 'maria@mail');
    await tester.enterText(find.byKey(const Key('signup-password')), 'short');
    await tapVisible(tester, find.byKey(const Key('signup-consent')));
    expect(isEnabled(tester, 'Дальше'), isFalse);

    await tester.enterText(
      find.byKey(const Key('signup-email')),
      'maria.k@mail.ru',
    );
    await tester.enterText(
      find.byKey(const Key('signup-password')),
      'trenirovka2026',
    );
    await tester.pump();
    expect(isEnabled(tester, 'Дальше'), isTrue);

    await tapVisible(tester, find.byKey(const Key('signup-consent')));
    expect(isEnabled(tester, 'Дальше'), isFalse);
  });

  testWidgets('body CTA needs sex and age between 18 and 100', (tester) async {
    await pumpApp(tester, location: Routes.body);
    expect(isEnabled(tester, 'Дальше'), isFalse);

    await tapVisible(tester, find.byKey(const Key('sex-female')));
    expect(isEnabled(tester, 'Дальше'), isFalse);

    await tester.enterText(find.byKey(const Key('body-age')), '16');
    await tester.pump();
    expect(isEnabled(tester, 'Дальше'), isFalse);

    await tester.enterText(find.byKey(const Key('body-age')), '31');
    await tester.pump();
    expect(isEnabled(tester, 'Дальше'), isTrue);
  });

  testWidgets('calibration tests collect manual results into CalibDone',
      (tester) async {
    await pumpApp(tester, location: Routes.calibrationTest);
    expect(isEnabled(tester, 'Дальше: отжимания'), isFalse);

    await tester.enterText(find.byKey(const Key('calib-squat-reps')), '24');
    await tester.pump();
    await tapVisible(tester, find.text('Дальше: отжимания'));

    expect(isEnabled(tester, 'Дальше: планка'), isFalse);
    await tapVisible(tester, find.byKey(const Key('pushup-floor')));
    await tester.enterText(find.byKey(const Key('calib-pushup-reps')), '9');
    await tester.pump();
    await tapVisible(tester, find.text('Дальше: планка'));

    expect(isEnabled(tester, 'Всё, отпускаю'), isFalse);
    await tester.enterText(find.byKey(const Key('calib-plank-seconds')), '42');
    await tester.pump();
    await tapVisible(tester, find.text('Всё, отпускаю'));

    expect(find.text('Проверка пройдена'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('0:42'), findsOneWidget);
    expect(find.text('от пола'), findsOneWidget);

    final viewModel = viewModelOf(tester);
    expect(viewModel.squatReps, 24);
    expect(viewModel.pushupReps, 9);
    expect(viewModel.pushupVariant, PushupVariant.floor);
    expect(viewModel.plankSeconds, 42);
  });

  testWidgets('plank stopwatch counts seconds and enables the CTA',
      (tester) async {
    await pumpApp(tester, location: Routes.calibrationTest);
    await tester.enterText(find.byKey(const Key('calib-squat-reps')), '10');
    await tester.pump();
    await tapVisible(tester, find.text('Дальше: отжимания'));
    await tester.enterText(find.byKey(const Key('calib-pushup-reps')), '5');
    await tester.pump();
    await tapVisible(tester, find.text('Дальше: планка'));

    await tester.tap(find.text('Старт'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('0:03'), findsOneWidget);
    expect(isEnabled(tester, 'Всё, отпускаю'), isTrue);

    await tapVisible(tester, find.text('Всё, отпускаю'));
    expect(viewModelOf(tester).plankSeconds, 3);
  });

  testWidgets('CalibDone CTA waits for difficulty, then plan leads home',
      (tester) async {
    final planBuilder = FakePlanBuilder();
    await pumpApp(
      tester,
      location: Routes.calibrationDone,
      planBuilder: planBuilder,
    );
    expect(isEnabled(tester, 'Составить план'), isFalse);

    await tapVisible(tester, find.byKey(const Key('difficulty-7')));
    expect(isEnabled(tester, 'Составить план'), isTrue);
    expect(viewModelOf(tester).answers.calibration?.perceivedDifficulty, 7);

    await tapVisible(tester, find.text('Составить план'));
    expect(find.text('Твой план готов'), findsOneWidget);
    expect(find.text('3 × 12'), findsOneWidget);
    expect(find.text('3 × 30 сек'), findsOneWidget);
    expect(planBuilder.lastAnswers?.calibration?.perceivedDifficulty, 7);

    await tapVisible(tester, find.text('К первой тренировке'));
    expect(find.text('Привет!'), findsOneWidget);
    expect(find.text('Главная'), findsOneWidget);
  });
}
