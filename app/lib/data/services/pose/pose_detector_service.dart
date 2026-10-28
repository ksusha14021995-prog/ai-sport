import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../../domain/technique/pose_frame.dart';
import 'camera_input_image.dart';

const _landmarkMapping = {
  PoseLandmarkType.nose: BodyLandmark.nose,
  PoseLandmarkType.leftShoulder: BodyLandmark.leftShoulder,
  PoseLandmarkType.rightShoulder: BodyLandmark.rightShoulder,
  PoseLandmarkType.leftElbow: BodyLandmark.leftElbow,
  PoseLandmarkType.rightElbow: BodyLandmark.rightElbow,
  PoseLandmarkType.leftWrist: BodyLandmark.leftWrist,
  PoseLandmarkType.rightWrist: BodyLandmark.rightWrist,
  PoseLandmarkType.leftHip: BodyLandmark.leftHip,
  PoseLandmarkType.rightHip: BodyLandmark.rightHip,
  PoseLandmarkType.leftKnee: BodyLandmark.leftKnee,
  PoseLandmarkType.rightKnee: BodyLandmark.rightKnee,
  PoseLandmarkType.leftAnkle: BodyLandmark.leftAnkle,
  PoseLandmarkType.rightAnkle: BodyLandmark.rightAnkle,
  PoseLandmarkType.leftHeel: BodyLandmark.leftHeel,
  PoseLandmarkType.rightHeel: BodyLandmark.rightHeel,
  PoseLandmarkType.leftFootIndex: BodyLandmark.leftFootIndex,
  PoseLandmarkType.rightFootIndex: BodyLandmark.rightFootIndex,
};

/// Обёртка над ML Kit Pose Detection: InputImage → доменный [PoseFrame]
/// в координатах превью (уже отзеркаленных для фронтальной камеры).
class PoseDetectorService {
  PoseDetectorService({this.model = PoseDetectionModel.base})
    : _detector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: model,
        ),
      );

  final PoseDetectionModel model;
  final PoseDetector _detector;

  /// null — человека в кадре нет.
  Future<PoseFrame?> detect(
    InputImage image,
    FrameGeometry geometry,
    Duration timestamp,
  ) async {
    final poses = await _detector.processImage(image);
    if (poses.isEmpty) return null;

    final width = geometry.uprightSize.width;
    final landmarks = <BodyLandmark, Landmark>{};
    for (final entry in poses.first.landmarks.entries) {
      final type = _landmarkMapping[entry.key];
      if (type == null) continue;
      final point = entry.value;
      landmarks[type] = Landmark(
        geometry.mirrorX ? width - point.x : point.x,
        point.y,
        likelihood: point.likelihood,
      );
    }
    return PoseFrame(landmarks: landmarks, timestamp: timestamp);
  }

  Future<void> close() => _detector.close();
}
