import 'package:ai_sport/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

Finder answerButton(int question, String label) => find.descendant(
      of: find.byKey(Key('screening-q$question')),
      matching: find.text(label),
    );

Future<void> answerAll(WidgetTester tester, {int? yesAt}) async {
  for (var i = 0; i < 9; i++) {
    await tapVisible(tester, answerButton(i, i == yesAt ? 'Да' : 'Нет'));
  }
}

void main() {
  testWidgets('shows 9 questions, Q8 asks about being under 18',
      (tester) async {
    await pumpApp(tester, location: Routes.screening);
    for (var i = 0; i < 9; i++) {
      await tester.ensureVisible(find.byKey(Key('screening-q$i')));
    }
    expect(find.text('Вам меньше 18 лет?'), findsOneWidget);
    expect(find.text('Вы беременны?'), findsOneWidget);
  });

  testWidgets('CTA stays disabled until every question is answered',
      (tester) async {
    await pumpApp(tester, location: Routes.screening);
    expect(find.text('Отвечено 0 из 9'), findsOneWidget);
    expect(isEnabled(tester, 'Дальше'), isFalse);

    for (var i = 0; i < 8; i++) {
      await tapVisible(tester, answerButton(i, 'Нет'));
    }
    expect(find.text('Отвечено 8 из 9'), findsOneWidget);
    expect(isEnabled(tester, 'Дальше'), isFalse);

    await tapVisible(tester, answerButton(8, 'Нет'));
    expect(find.text('Отвечено 9 из 9'), findsOneWidget);
    expect(isEnabled(tester, 'Дальше'), isTrue);
  });

  testWidgets('re-answering a question does not inflate the counter',
      (tester) async {
    await pumpApp(tester, location: Routes.screening);
    await tapVisible(tester, answerButton(0, 'Нет'));
    await tapVisible(tester, answerButton(0, 'Да'));
    expect(find.text('Отвечено 1 из 9'), findsOneWidget);
  });

  testWidgets('all answers "Нет" lead to the goal screen', (tester) async {
    await pumpApp(tester, location: Routes.screening);
    await answerAll(tester);
    await tester.tap(find.text('Дальше'));
    await tester.pumpAndSettle();
    expect(find.text('Цель и возможности'), findsOneWidget);
  });

  for (final yesAt in [0, 7, 8]) {
    testWidgets('"Да" on question ${yesAt + 1} redirects to the stop screen',
        (tester) async {
      await pumpApp(tester, location: Routes.screening);
      await answerAll(tester, yesAt: yesAt);
      await tester.tap(find.text('Дальше'));
      await tester.pumpAndSettle();
      expect(find.text('Сначала — к врачу'), findsOneWidget);
      expect(viewModelOf(tester).isScreeningPassed, isFalse);

      await tester.tap(find.text('Изменить ответы'));
      await tester.pumpAndSettle();
      expect(find.text('Сначала — о здоровье'), findsOneWidget);
    });
  }
}
