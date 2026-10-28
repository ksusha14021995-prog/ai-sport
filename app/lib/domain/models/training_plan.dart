import 'onboarding.dart';

enum PlanLevel { beginner, intermediate, advanced }

/// Стартовая норма упражнения: либо повторы, либо секунды удержания.
class PlanExercise {
  final String exerciseId;
  final String title;
  final int sets;
  final int? reps;
  final int? holdSeconds;

  const PlanExercise({
    required this.exerciseId,
    required this.title,
    required this.sets,
    this.reps,
    this.holdSeconds,
  }) : assert((reps == null) != (holdSeconds == null));
}

class TrainingPlan {
  final String templateId;
  final String title;
  final PlanLevel level;
  final int weeks;
  final int sessionsPerWeek;
  final int minutesPerSession;
  final List<PlanExercise> startingExercises;

  const TrainingPlan({
    required this.templateId,
    required this.title,
    required this.level,
    required this.weeks,
    required this.sessionsPerWeek,
    required this.minutesPerSession,
    required this.startingExercises,
  });
}

abstract interface class PlanBuilder {
  /// Бросает [StateError], если скрининг не пройден или калибровки нет.
  Future<TrainingPlan> build(OnboardingAnswers answers);
}
