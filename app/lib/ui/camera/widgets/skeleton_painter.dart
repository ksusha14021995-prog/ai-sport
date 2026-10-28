import 'package:flutter/material.dart';

import '../../../domain/technique/pose_frame.dart';
import '../view_models/camera_workout_view_model.dart';
import 'camera_palette.dart';

const _bones = [
  (BodyLandmark.leftShoulder, BodyLandmark.rightShoulder),
  (BodyLandmark.leftShoulder, BodyLandmark.leftElbow),
  (BodyLandmark.leftElbow, BodyLandmark.leftWrist),
  (BodyLandmark.rightShoulder, BodyLandmark.rightElbow),
  (BodyLandmark.rightElbow, BodyLandmark.rightWrist),
  (BodyLandmark.leftShoulder, BodyLandmark.leftHip),
  (BodyLandmark.rightShoulder, BodyLandmark.rightHip),
  (BodyLandmark.leftHip, BodyLandmark.rightHip),
  (BodyLandmark.leftHip, BodyLandmark.leftKnee),
  (BodyLandmark.leftKnee, BodyLandmark.leftAnkle),
  (BodyLandmark.rightHip, BodyLandmark.rightKnee),
  (BodyLandmark.rightKnee, BodyLandmark.rightAnkle),
  (BodyLandmark.leftAnkle, BodyLandmark.leftHeel),
  (BodyLandmark.leftHeel, BodyLandmark.leftFootIndex),
  (BodyLandmark.rightAnkle, BodyLandmark.rightHeel),
  (BodyLandmark.rightHeel, BodyLandmark.rightFootIndex),
];

const _joints = [
  BodyLandmark.leftShoulder,
  BodyLandmark.rightShoulder,
  BodyLandmark.leftElbow,
  BodyLandmark.rightElbow,
  BodyLandmark.leftWrist,
  BodyLandmark.rightWrist,
  BodyLandmark.leftHip,
  BodyLandmark.rightHip,
  BodyLandmark.leftAnkle,
  BodyLandmark.rightAnkle,
];

/// Скелет поверх превью. Координаты уже в системе «вертикального» кадра
/// и отзеркалены для фронтальной камеры (см. PoseDetectorService),
/// здесь только масштаб под размер превью.
class SkeletonPainter extends CustomPainter {
  SkeletonPainter({
    required this.overlay,
    required this.kneesIn,
    this.minLikelihood = 0.5,
  });

  final PoseOverlay? overlay;
  final bool kneesIn;
  final double minLikelihood;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = this.overlay;
    if (overlay == null) return;
    final scaleX = size.width / overlay.uprightSize.width;
    final scaleY = size.height / overlay.uprightSize.height;
    final frame = overlay.frame;

    Offset? point(BodyLandmark type) {
      final landmark = frame.confident(type, minLikelihood);
      if (landmark == null) return null;
      return Offset(landmark.x * scaleX, landmark.y * scaleY);
    }

    final unit = size.shortestSide / 100;
    final bonePaint = Paint()
      ..color = CameraPalette.accent
      ..strokeWidth = unit * 1.2
      ..strokeCap = StrokeCap.round;
    for (final (from, to) in _bones) {
      final a = point(from);
      final b = point(to);
      if (a != null && b != null) canvas.drawLine(a, b, bonePaint);
    }

    final leftShoulder = point(BodyLandmark.leftShoulder);
    final rightShoulder = point(BodyLandmark.rightShoulder);
    final nose = point(BodyLandmark.nose);
    if (nose != null && leftShoulder != null && rightShoulder != null) {
      final radius = (leftShoulder - rightShoulder).distance * 0.3;
      canvas.drawCircle(
        nose,
        radius,
        Paint()
          ..color = CameraPalette.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit,
      );
    }

    final jointPaint = Paint()..color = Colors.white;
    for (final type in _joints) {
      final p = point(type);
      if (p != null) canvas.drawCircle(p, unit * 1.6, jointPaint);
    }

    final kneePaint = Paint()
      ..color = kneesIn ? CameraPalette.errorJoint : Colors.white;
    for (final type in [BodyLandmark.leftKnee, BodyLandmark.rightKnee]) {
      final p = point(type);
      if (p != null) canvas.drawCircle(p, unit * 2.4, kneePaint);
    }
  }

  @override
  bool shouldRepaint(SkeletonPainter oldDelegate) =>
      oldDelegate.overlay != overlay || oldDelegate.kneesIn != kneesIn;
}
