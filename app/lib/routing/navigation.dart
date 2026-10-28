import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension PopOrGo on BuildContext {
  /// «Назад» в онбординге: экран мог быть открыт диплинком без стека.
  void popOrGo(String fallbackLocation) {
    if (canPop()) {
      pop();
    } else {
      go(fallbackLocation);
    }
  }
}
