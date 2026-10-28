import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../ui/camera/camera_workout_screen.dart';
import '../ui/home/home_screen.dart';
import '../ui/library/library_screen.dart';
import '../ui/onboarding/widgets/body_screen.dart';
import '../ui/onboarding/widgets/calibration_done_screen.dart';
import '../ui/onboarding/widgets/calibration_intro_screen.dart';
import '../ui/onboarding/widgets/calibration_test_screen.dart';
import '../ui/onboarding/widgets/goal_screen.dart';
import '../ui/onboarding/widgets/plan_ready_screen.dart';
import '../ui/onboarding/widgets/screening_screen.dart';
import '../ui/onboarding/widgets/signup_screen.dart';
import '../ui/onboarding/widgets/stop_screen.dart';
import '../ui/onboarding/widgets/welcome_screen.dart';
import '../ui/profile/profile_screen.dart';
import '../ui/progress/progress_screen.dart';
import '../ui/shell/app_shell.dart';
import 'routes.dart';

GoRouter createRouter({String initialLocation = Routes.welcome}) {
  GoRoute screen(String path, Widget Function() build) =>
      GoRoute(path: path, builder: (context, state) => build());

  StatefulShellBranch tab(String path, Widget Function() build) =>
      StatefulShellBranch(routes: [screen(path, build)]);

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      screen(Routes.welcome, () => const WelcomeScreen()),
      screen(Routes.signup, () => const SignupScreen()),
      screen(Routes.screening, () => const ScreeningScreen()),
      screen(Routes.stop, () => const StopScreen()),
      screen(Routes.goal, () => const GoalScreen()),
      screen(Routes.body, () => const BodyScreen()),
      screen(Routes.calibration, () => const CalibrationIntroScreen()),
      screen(Routes.calibrationTest, () => const CalibrationTestScreen()),
      screen(Routes.calibrationDone, () => const CalibrationDoneScreen()),
      screen(Routes.planReady, () => const PlanReadyScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          tab(Routes.home, () => const HomeScreen()),
          tab(Routes.library, () => const LibraryScreen()),
          tab(Routes.progress, () => const ProgressScreen()),
          tab(Routes.profile, () => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: Routes.cameraPattern,
        builder: (context, state) => CameraWorkoutScreen(
          exerciseId: state.pathParameters['exerciseId']!,
        ),
      ),
    ],
  );
}
