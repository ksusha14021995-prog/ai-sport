enum SquatPhase {
  /// Ещё не видели человека стоящим — повторы не считаем.
  notReady,
  standing,
  descending,
  bottom,
  ascending,
}

enum TechniqueError {
  /// Колени уходят внутрь (вальгус).
  kneesIn,

  /// Опустился, но не до нижнего порога и встал — недосед.
  notDeepEnough,
}

class SquatState {
  const SquatState({
    this.reps = 0,
    this.currentAngle,
    this.phase = SquatPhase.notReady,
    this.activeError,
    this.poseVisible = false,
    this.repsWithErrors = 0,
    this.errorCounts = const {},
  });

  final int reps;

  /// Сглаженный угол в колене (градусы) или null, если ноги не видно.
  final double? currentAngle;
  final SquatPhase phase;
  final TechniqueError? activeError;

  /// В последнем кадре была хотя бы одна нога с уверенными точками.
  final bool poseVisible;

  /// Засчитанные повторы, в которых была хотя бы одна ошибка.
  final int repsWithErrors;

  /// Сколько раз поднималась каждая ошибка за подход.
  final Map<TechniqueError, int> errorCounts;

  SquatState copyWith({
    int? reps,
    double? Function()? currentAngle,
    SquatPhase? phase,
    TechniqueError? Function()? activeError,
    bool? poseVisible,
    int? repsWithErrors,
    Map<TechniqueError, int>? errorCounts,
  }) {
    return SquatState(
      reps: reps ?? this.reps,
      currentAngle: currentAngle != null ? currentAngle() : this.currentAngle,
      phase: phase ?? this.phase,
      activeError: activeError != null ? activeError() : this.activeError,
      poseVisible: poseVisible ?? this.poseVisible,
      repsWithErrors: repsWithErrors ?? this.repsWithErrors,
      errorCounts: errorCounts ?? this.errorCounts,
    );
  }
}

sealed class TechniqueEvent {
  const TechniqueEvent(this.timestamp);
  final Duration timestamp;
}

class RepCompleted extends TechniqueEvent {
  const RepCompleted(
    super.timestamp, {
    required this.reps,
    required this.minAngle,
    required this.hadError,
  });
  final int reps;
  final double minAngle;
  final bool hadError;
}

class TechniqueErrorRaised extends TechniqueEvent {
  const TechniqueErrorRaised(super.timestamp, this.error);
  final TechniqueError error;
}
