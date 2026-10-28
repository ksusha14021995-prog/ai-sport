import '../models/onboarding.dart';
import '../models/training_plan.dart';
import 'plan_template.dart';

/// Детерминированные правила подбора плана: уровень → шаблон → стартовые нормы.
abstract final class PlanRules {
  /// Меньше стольких отжиманий от пола — даём вариант с колен.
  static const kneesThreshold = 5;

  /// Одно отжимание от пола ≈ двум с колен (для оценки уровня и перевода нормы).
  static const kneesPerFloorPushup = 2;

  /// «Тяжело» (≥ 8) — уровень на ступень ниже и нормы ×0.8.
  static const hardDifficulty = 8;
  static const hardDoseScale = 0.8;

  /// «Легко» (≤ 3) — уровень на ступень выше.
  static const easyDifficulty = 3;

  static const kneesExerciseId = 'pushup_knees';
  static const kneesTitle = 'Отжимания с колен';

  static TrainingPlan build(
    List<PlanTemplate> templates,
    OnboardingAnswers answers,
  ) {
    if (!answers.screening.isPassed) {
      throw StateError('Скрининг не пройден — план не выдаётся');
    }
    final calibration = answers.calibration;
    if (calibration == null) {
      throw StateError('Нет результатов калибровки — план не выдаётся');
    }
    if (templates.isEmpty) {
      throw StateError('Нет ни одного шаблона плана');
    }

    final level = levelFor(answers.experience ?? Experience.none, calibration);
    final template = selectTemplate(templates, answers, level);
    final knees = useKnees(calibration);
    final doseScale = calibration.perceivedDifficulty >= hardDifficulty
        ? hardDoseScale
        : 1.0;

    return TrainingPlan(
      templateId: template.id,
      title: template.title,
      level: level,
      weeks: template.weeks,
      sessionsPerWeek: sessionsFor(template, answers.daysPerWeek),
      minutesPerSession:
          answers.minutesPerSession ?? template.minutesPerSession.first,
      startingExercises: [
        for (final exercise in template.exercises)
          _exerciseFor(
            exercise,
            level,
            calibration,
            knees: knees,
            doseScale: doseScale,
          ),
      ],
    );
  }

  /// Уровень по калибровке, не выше «опыт + 1 ступень»; потом поправка на «тяжело/легко».
  static PlanLevel levelFor(
    Experience experience,
    CalibrationResult calibration,
  ) {
    final experienceCap = switch (experience) {
      Experience.none || Experience.under6Months => 1,
      Experience.from6To24Months || Experience.over2Years => 2,
    };
    final difficultyShift = switch (calibration.perceivedDifficulty) {
      >= hardDifficulty => -1,
      <= easyDifficulty => 1,
      _ => 0,
    };
    final index = (_calibrationIndex(calibration) + difficultyShift)
        .clamp(0, experienceCap)
        .clamp(0, PlanLevel.values.length - 1);
    return PlanLevel.values[index];
  }

  /// 0/1/2 очка за каждое упражнение калибровки → сумма 0–6 → уровень.
  static int _calibrationIndex(CalibrationResult c) {
    final floorPushups = c.pushupVariant == PushupVariant.knees
        ? c.pushupReps ~/ kneesPerFloorPushup
        : c.pushupReps;
    final points =
        _points(c.squatReps, 25, 40) +
        _points(floorPushups, 8, 20) +
        _points(c.plankSeconds, 45, 90);
    return switch (points) {
      <= 1 => 0,
      <= 4 => 1,
      _ => 2,
    };
  }

  static int _points(int value, int intermediateFrom, int advancedFrom) =>
      switch (value) {
        _ when value >= advancedFrom => 2,
        _ when value >= intermediateFrom => 1,
        _ => 0,
      };

  static bool useKnees(CalibrationResult c) =>
      c.pushupVariant == PushupVariant.knees || c.pushupReps < kneesThreshold;

  /// Сортировка по ключам по очереди: ближе уровень → подходит опыт →
  /// больше общих целей → ближе дни → ближе минуты → id по алфавиту.
  static PlanTemplate selectTemplate(
    List<PlanTemplate> templates,
    OnboardingAnswers answers,
    PlanLevel level,
  ) {
    final experience = answers.experience ?? Experience.none;
    List<int> score(PlanTemplate t) => [
      t.levels.map((l) => (l.index - level.index).abs()).reduce(_min),
      t.fitsExperience(experience) ? 0 : 1,
      -t.goals.intersection(answers.goals).length,
      _distance(t.sessionsPerWeek, answers.daysPerWeek),
      _distance(t.minutesPerSession, answers.minutesPerSession),
    ];

    final ranked = [...templates]
      ..sort((a, b) {
        final sa = score(a), sb = score(b);
        for (var i = 0; i < sa.length; i++) {
          if (sa[i] != sb[i]) return sa[i].compareTo(sb[i]);
        }
        return a.id.compareTo(b.id);
      });
    return ranked.first;
  }

  /// Дни пользователя, но не больше максимума шаблона.
  static int sessionsFor(PlanTemplate template, int? daysPerWeek) {
    final max = template.sessionsPerWeek.last;
    if (daysPerWeek == null) return template.sessionsPerWeek.first;
    return daysPerWeek < max ? daysPerWeek : max;
  }

  static PlanExercise _exerciseFor(
    ExerciseTemplate exercise,
    PlanLevel level,
    CalibrationResult calibration, {
    required bool knees,
    required double doseScale,
  }) {
    final isKneesPushup = knees && exercise.exerciseId == 'pushup';
    int? dose(DoseRule? rule) =>
        rule == null ? null : _resolve(rule, calibration, doseScale: doseScale);
    return PlanExercise(
      exerciseId: isKneesPushup ? kneesExerciseId : exercise.exerciseId,
      title: isKneesPushup ? kneesTitle : exercise.title,
      sets: exercise.setsFor(level),
      reps: dose(exercise.reps),
      holdSeconds: exercise.holdSeconds == null
          ? null
          : _roundTo5(dose(exercise.holdSeconds)!, exercise.holdSeconds!),
    );
  }

  static int _resolve(
    DoseRule rule,
    CalibrationResult c, {
    required double doseScale,
  }) => switch (rule) {
    FixedDose(:final value) => value,
    CalibrationDose(:final from, :final factor, :final min, :final max) =>
      (_metric(from, c) * factor * doseScale).round().clamp(min, max),
  };

  /// Секунды планки — кратно 5, но в пределах min/max шаблона.
  static int _roundTo5(int seconds, DoseRule rule) {
    final rounded = (seconds / 5).round() * 5;
    return switch (rule) {
      CalibrationDose(:final min, :final max) => rounded.clamp(min, max),
      FixedDose() => seconds,
    };
  }

  /// Отжимания от пола, переведённые в «с колен», если пользователь не справился.
  static int _metric(CalibrationMetric metric, CalibrationResult c) =>
      switch (metric) {
        CalibrationMetric.squatReps => c.squatReps,
        CalibrationMetric.plankSeconds => c.plankSeconds,
        CalibrationMetric.pushupReps
            when c.pushupVariant == PushupVariant.floor && useKnees(c) =>
          c.pushupReps * kneesPerFloorPushup,
        CalibrationMetric.pushupReps => c.pushupReps,
      };

  static int _distance(List<int> options, int? wanted) =>
      wanted == null ? 0 : options.map((o) => (o - wanted).abs()).reduce(_min);

  static int _min(int a, int b) => a < b ? a : b;
}
