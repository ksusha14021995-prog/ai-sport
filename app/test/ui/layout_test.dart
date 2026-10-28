import 'package:ai_sport/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  const screens = {
    Routes.welcome: 'Начать',
    Routes.signup: 'Дальше',
    Routes.screening: 'Дальше',
    Routes.stop: 'Изменить ответы',
    Routes.goal: 'Дальше',
    Routes.body: 'Дальше',
    Routes.calibration: 'Начать проверку',
    Routes.calibrationTest: 'Дальше: отжимания',
    Routes.calibrationDone: 'Составить план',
    Routes.planReady: 'К первой тренировке',
    Routes.home: 'Начать тренировку',
    Routes.library: 'Упражнения',
    Routes.progress: 'Прогресс',
    Routes.profile: 'Профиль',
  };

  for (final size in [phoneSmall, phoneLarge]) {
    final sizeLabel = '${size.width.toInt()}x${size.height.toInt()}';
    for (final MapEntry(key: location, value: anchorText) in screens.entries) {
      testWidgets('$location renders without overflow at $sizeLabel',
          (tester) async {
        await pumpApp(tester, location: location, size: size);
        expect(tester.takeException(), isNull);
        expect(find.text(anchorText), findsWidgets);
      });
    }
  }

  testWidgets('onboarding CTA is pinned on screen and 56 px tall',
      (tester) async {
    await pumpApp(tester, location: Routes.screening, size: phoneSmall);
    final cta = tester.getRect(primaryButtonFinder('Дальше'));
    expect(cta.height, 56);
    expect(cta.bottom, lessThanOrEqualTo(phoneSmall.height));
  });
}
