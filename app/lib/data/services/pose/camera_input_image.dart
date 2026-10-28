import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Формат кадров, который ML Kit принимает из image stream одним plane.
ImageFormatGroup get mlKitImageFormatGroup =>
    Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888;

const _deviceOrientationDegrees = {
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

/// Поворот кадра — по официальному примеру google_mlkit_commons.
/// На Android используется при конвертации, на iOS — только для координат.
InputImageRotation? inputImageRotation(
  CameraDescription camera,
  DeviceOrientation deviceOrientation,
) {
  final sensorOrientation = camera.sensorOrientation;
  if (Platform.isIOS) {
    return InputImageRotationValue.fromRawValue(sensorOrientation);
  }
  var compensation = _deviceOrientationDegrees[deviceOrientation];
  if (compensation == null) return null;
  if (camera.lensDirection == CameraLensDirection.front) {
    compensation = (sensorOrientation + compensation) % 360;
  } else {
    compensation = (sensorOrientation - compensation + 360) % 360;
  }
  return InputImageRotationValue.fromRawValue(compensation);
}

InputImage? inputImageFromCameraImage(
  CameraImage image,
  InputImageRotation rotation,
) {
  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (format == null ||
      (Platform.isAndroid && format != InputImageFormat.nv21) ||
      (Platform.isIOS && format != InputImageFormat.bgra8888)) {
    return null;
  }
  // nv21 и bgra8888 приходят одним plane.
  if (image.planes.length != 1) return null;
  final plane = image.planes.first;

  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    ),
  );
}

/// Как координаты ML Kit лечь на превью: размер «вертикального» кадра и
/// нужно ли отзеркалить X. Логика повторяет coordinates_translator из
/// официального example-приложения google_ml_kit_flutter.
class FrameGeometry {
  const FrameGeometry({required this.uprightSize, required this.mirrorX});

  factory FrameGeometry.from({
    required Size imageSize,
    required InputImageRotation rotation,
    required CameraLensDirection lensDirection,
  }) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        final upright = Platform.isIOS
            ? imageSize
            : Size(imageSize.height, imageSize.width);
        return FrameGeometry(
          uprightSize: upright,
          mirrorX: rotation == InputImageRotation.rotation270deg,
        );
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        return FrameGeometry(
          uprightSize: imageSize,
          mirrorX: lensDirection != CameraLensDirection.back,
        );
    }
  }

  /// Размер кадра в той ориентации, в которой ML Kit отдаёт координаты.
  final Size uprightSize;

  /// Фронтальная камера: превью зеркальное, координаты — нет.
  final bool mirrorX;
}
