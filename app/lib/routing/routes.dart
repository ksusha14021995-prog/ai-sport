abstract final class Routes {
  static const welcome = '/';
  static const signup = '/onboarding/signup';
  static const screening = '/onboarding/screening';
  static const stop = '/onboarding/stop';
  static const goal = '/onboarding/goal';
  static const body = '/onboarding/body';
  static const calibration = '/onboarding/calibration';
  static const calibrationTest = '/onboarding/calibration/test';
  static const calibrationDone = '/onboarding/calibration/done';
  static const planReady = '/onboarding/plan';

  static const home = '/home';
  static const library = '/library';
  static const progress = '/progress';
  static const profile = '/profile';

  static const cameraPattern = '/camera/:exerciseId';
  static String camera(String exerciseId) => '/camera/$exerciseId';
}
