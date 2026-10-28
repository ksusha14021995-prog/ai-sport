/// Точки тела, которые использует анализ техники и отрисовка скелета.
/// Подмножество 33 точек ML Kit / BlazePose.
enum BodyLandmark {
  nose,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
  leftHeel,
  rightHeel,
  leftFootIndex,
  rightFootIndex,
}

class Landmark {
  const Landmark(this.x, this.y, {this.likelihood = 1.0});

  /// Координаты в пикселях кадра, приведённого к вертикальной ориентации экрана.
  final double x;
  final double y;

  /// Уверенность детектора, 0..1.
  final double likelihood;
}

/// Одна поза в одном кадре. Не зависит от ML Kit, чтобы логику можно было
/// гонять в unit-тестах на синтетике.
class PoseFrame {
  const PoseFrame({required this.landmarks, required this.timestamp});

  final Map<BodyLandmark, Landmark> landmarks;

  /// Время кадра от начала сессии (монотонное).
  final Duration timestamp;

  Landmark? operator [](BodyLandmark type) => landmarks[type];

  /// Точка, только если детектор в ней достаточно уверен.
  Landmark? confident(BodyLandmark type, double minLikelihood) {
    final landmark = landmarks[type];
    if (landmark == null || landmark.likelihood < minLikelihood) return null;
    return landmark;
  }
}
