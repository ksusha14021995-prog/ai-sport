enum Goal { loseWeight, gainMass, getStronger, endurance, tone }

enum Experience { none, under6Months, from6To24Months, over2Years }

enum Sex { female, male }

enum PushupVariant { floor, knees }

/// 9 вопросов скрининга из схемы онбординга. Любое «да» — стоп, в MVP не пускаем.
class ScreeningAnswers {
  static const questionCount = 9;

  final List<bool?> answers;

  ScreeningAnswers([List<bool?>? answers])
      : answers = List.unmodifiable(
            answers ?? List<bool?>.filled(questionCount, null));

  bool get isComplete => !answers.contains(null);

  bool get isPassed => isComplete && !answers.contains(true);

  ScreeningAnswers answer(int index, bool value) {
    final updated = [...answers]..[index] = value;
    return ScreeningAnswers(updated);
  }
}

class CalibrationResult {
  final int squatReps;
  final int squatErrors;
  final int pushupReps;
  final PushupVariant pushupVariant;
  final int plankSeconds;
  final int plankErrors;

  /// «Насколько было тяжело?» 1–10.
  final int perceivedDifficulty;

  const CalibrationResult({
    required this.squatReps,
    required this.squatErrors,
    required this.pushupReps,
    required this.pushupVariant,
    required this.plankSeconds,
    required this.plankErrors,
    required this.perceivedDifficulty,
  });
}

class OnboardingAnswers {
  final ScreeningAnswers screening;
  final Set<Goal> goals;
  final Experience? experience;

  /// 2, 3, 4 или 5 (5 = «5+»).
  final int? daysPerWeek;

  /// 15, 30, 45 или 60.
  final int? minutesPerSession;
  final Sex? sex;
  final int? age;
  final int? heightCm;
  final double? weightKg;
  final CalibrationResult? calibration;

  OnboardingAnswers({
    ScreeningAnswers? screening,
    this.goals = const {},
    this.experience,
    this.daysPerWeek,
    this.minutesPerSession,
    this.sex,
    this.age,
    this.heightCm,
    this.weightKg,
    this.calibration,
  }) : screening = screening ?? ScreeningAnswers();

  OnboardingAnswers copyWith({
    ScreeningAnswers? screening,
    Set<Goal>? goals,
    Experience? experience,
    int? daysPerWeek,
    int? minutesPerSession,
    Sex? sex,
    int? age,
    int? heightCm,
    double? weightKg,
    CalibrationResult? calibration,
  }) {
    return OnboardingAnswers(
      screening: screening ?? this.screening,
      goals: goals ?? this.goals,
      experience: experience ?? this.experience,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      minutesPerSession: minutesPerSession ?? this.minutesPerSession,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      calibration: calibration ?? this.calibration,
    );
  }
}
