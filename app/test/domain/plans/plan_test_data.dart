import 'package:ai_sport/domain/models/onboarding.dart';
import 'package:ai_sport/domain/plans/plan_template.dart';

ScreeningAnswers passedScreening() =>
    ScreeningAnswers(List.filled(ScreeningAnswers.questionCount, false));

CalibrationResult calibration({
  int squats = 24,
  int pushups = 9,
  PushupVariant variant = PushupVariant.knees,
  int plank = 42,
  int difficulty = 6,
}) => CalibrationResult(
  squatReps: squats,
  squatErrors: 2,
  pushupReps: pushups,
  pushupVariant: variant,
  plankSeconds: plank,
  plankErrors: 1,
  perceivedDifficulty: difficulty,
);

OnboardingAnswers answers({
  Set<Goal> goals = const {Goal.tone},
  Experience experience = Experience.none,
  int days = 3,
  int minutes = 30,
  CalibrationResult? calib,
  ScreeningAnswers? screening,
}) => OnboardingAnswers(
  screening: screening ?? passedScreening(),
  goals: goals,
  experience: experience,
  daysPerWeek: days,
  minutesPerSession: minutes,
  sex: Sex.female,
  age: 30,
  calibration: calib ?? calibration(),
);

/// Минимальный шаблон для тестов правил выбора.
PlanTemplate template(
  String id, {
  List<String> goals = const ['tone'],
  List<String> levels = const ['beginner'],
  String experienceFrom = 'none',
  String experienceTo = 'over2Years',
  List<int> sessions = const [2, 3],
  List<int> minutes = const [30],
}) => PlanTemplate.fromJson({
  'id': id,
  'title': id,
  'goals': goals,
  'levels': levels,
  'experience': {'from': experienceFrom, 'to': experienceTo},
  'sessionsPerWeek': sessions,
  'minutesPerSession': minutes,
  'weeks': 8,
  'exercises': [
    {
      'exerciseId': 'squat',
      'title': 'Приседания',
      'sets': 3,
      'reps': {'from': 'squatReps', 'factor': 0.5, 'min': 8, 'max': 20},
    },
  ],
});
