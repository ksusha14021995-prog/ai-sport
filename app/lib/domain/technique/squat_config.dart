/// Пороги анализа приседа. Подбирает Оля (CV/ML) по записям с реальных
/// телефонов; позже — персональные пороги на пользователя.
class SquatConfig {
  const SquatConfig({
    this.minLandmarkLikelihood = 0.5,
    this.standingAngle = 160,
    this.bottomAngle = 100,
    this.shallowRepAngle = 140,
    this.targetDepthAngle = 90,
    this.angleSmoothing = 0.6,
    this.valgusRatio = 0.8,
    this.valgusClearRatio = 0.9,
    this.valgusMaxKneeAngle = 140,
    this.valgusMinFrames = 3,
    this.frontalViewMinAnkleToTorso = 0.25,
    this.errorHold = const Duration(milliseconds: 2500),
  }) : assert(bottomAngle < shallowRepAngle && shallowRepAngle < standingAngle),
       assert(valgusRatio < valgusClearRatio),
       assert(angleSmoothing > 0 && angleSmoothing <= 1);

  /// Точки с likelihood ниже — игнорируются; кадр без пригодной ноги
  /// (бедро-колено-лодыжка) не меняет состояние счётчика.
  final double minLandmarkLikelihood;

  /// Угол в колене выше — человек стоит (верх повтора).
  final double standingAngle;

  /// Угол в колене ниже — нижняя точка достигнута, повтор засчитается при подъёме.
  /// Зазор standingAngle..bottomAngle — гистерезис против дребезга.
  final double bottomAngle;

  /// Если опустился ниже этого угла, но не до [bottomAngle] и встал —
  /// это недосед (ошибка notDeepEnough). Выше — считаем, что просто покачнулся.
  final double shallowRepAngle;

  /// Целевой угол для UI («цель — 90°»).
  final double targetDepthAngle;

  /// Коэффициент EMA для угла: 1.0 — без сглаживания, меньше — плавнее, но с задержкой.
  final double angleSmoothing;

  /// Вальгус: (расстояние между коленями по X) / (между лодыжками по X) ниже этого
  /// значения — колени уходят внутрь.
  final double valgusRatio;

  /// Ошибка kneesIn снимается, когда отношение поднялось выше этого значения.
  final double valgusClearRatio;

  /// Вальгус проверяем только в приседе (угол в колене ниже этого).
  final double valgusMaxKneeAngle;

  /// Сколько кадров подряд должно быть нарушение, чтобы поднять ошибку.
  final int valgusMinFrames;

  /// Вальгус по X осмыслен только во фронтальном ракурсе: требуем, чтобы
  /// лодыжки были разнесены хотя бы на эту долю длины корпуса (плечи→таз).
  final double frontalViewMinAnkleToTorso;

  /// Сколько держать на экране кратковременную ошибку (недосед).
  final Duration errorHold;
}
