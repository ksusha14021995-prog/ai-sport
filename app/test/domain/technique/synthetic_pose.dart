import 'dart:math' as math;

import 'package:ai_sport/domain/technique/pose_frame.dart';

/// Синтетическая фронтальная поза с заданным углом в колене.
/// Лодыжки на ±[ankleHalfSpread], колени на ±[kneeHalfSpread] (меньше — вальгус).
Map<BodyLandmark, Landmark> syntheticSquatPose(
  double kneeAngle, {
  double kneeHalfSpread = 60,
  double ankleHalfSpread = 60,
  double likelihood = 0.99,
}) {
  const shin = 100.0;
  const thigh = 100.0;
  const ankleY = 500.0;
  final theta = kneeAngle * math.pi / 180;
  final landmarks = <BodyLandmark, Landmark>{};

  Landmark hipFor(Landmark knee, Landmark ankle, {required bool left}) {
    final dx = ankle.x - knee.x;
    final dy = ankle.y - knee.y;
    final length = math.sqrt(dx * dx + dy * dy);
    final ux = dx / length;
    final uy = dy / length;
    final sign = left ? -1 : 1;
    final vx = ux * math.cos(theta) - sign * uy * math.sin(theta);
    final vy = sign * ux * math.sin(theta) + uy * math.cos(theta);
    return Landmark(
      knee.x + thigh * vx,
      knee.y + thigh * vy,
      likelihood: likelihood,
    );
  }

  for (final left in [true, false]) {
    final side = left ? -1 : 1;
    final ankle = Landmark(
      side * ankleHalfSpread,
      ankleY,
      likelihood: likelihood,
    );
    final knee = Landmark(
      side * kneeHalfSpread,
      ankleY - shin,
      likelihood: likelihood,
    );
    final hip = hipFor(knee, ankle, left: left);
    landmarks[left ? BodyLandmark.leftAnkle : BodyLandmark.rightAnkle] = ankle;
    landmarks[left ? BodyLandmark.leftKnee : BodyLandmark.rightKnee] = knee;
    landmarks[left ? BodyLandmark.leftHip : BodyLandmark.rightHip] = hip;
  }

  final hipY =
      (landmarks[BodyLandmark.leftHip]!.y +
          landmarks[BodyLandmark.rightHip]!.y) /
      2;
  landmarks[BodyLandmark.leftShoulder] = Landmark(
    -60,
    hipY - 200,
    likelihood: likelihood,
  );
  landmarks[BodyLandmark.rightShoulder] = Landmark(
    60,
    hipY - 200,
    likelihood: likelihood,
  );
  return landmarks;
}

/// Генератор последовательности кадров с монотонным временем (30 fps).
class FrameSequence {
  final frames = <PoseFrame>[];

  Duration get _next =>
      Duration(microseconds: (frames.length * 1e6 / 30).round());

  void add(
    double angle, {
    double kneeHalfSpread = 60,
    double ankleHalfSpread = 60,
    double likelihood = 0.99,
  }) {
    frames.add(
      PoseFrame(
        landmarks: syntheticSquatPose(
          angle,
          kneeHalfSpread: kneeHalfSpread,
          ankleHalfSpread: ankleHalfSpread,
          likelihood: likelihood,
        ),
        timestamp: _next,
      ),
    );
  }

  void hold(
    double angle,
    int count, {
    double kneeHalfSpread = 60,
    double likelihood = 0.99,
  }) {
    for (var i = 0; i < count; i++) {
      add(angle, kneeHalfSpread: kneeHalfSpread, likelihood: likelihood);
    }
  }

  void sweep(
    double from,
    double to, {
    double step = 5,
    double kneeHalfSpread = 60,
    double likelihood = 0.99,
  }) {
    final direction = to > from ? 1 : -1;
    for (
      var angle = from;
      direction > 0 ? angle <= to : angle >= to;
      angle += direction * step
    ) {
      add(angle, kneeHalfSpread: kneeHalfSpread, likelihood: likelihood);
    }
  }

  /// Полный повтор: стоя → [bottom] → стоя.
  void rep({
    double top = 175,
    double bottom = 80,
    double kneeHalfSpread = 60,
    double likelihood = 0.99,
  }) {
    hold(top, 5, likelihood: likelihood);
    sweep(top, bottom, likelihood: likelihood);
    hold(bottom, 5, kneeHalfSpread: kneeHalfSpread, likelihood: likelihood);
    sweep(bottom, top, likelihood: likelihood);
    hold(top, 5, likelihood: likelihood);
  }
}
