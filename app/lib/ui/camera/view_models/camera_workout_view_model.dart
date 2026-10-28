import 'dart:async';
import 'dart:collection';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../../data/services/pose/camera_input_image.dart';
import '../../../data/services/pose/pose_detector_service.dart';
import '../../../domain/technique/pose_frame.dart';
import '../../../domain/technique/squat_analyzer.dart';
import '../../../domain/technique/squat_config.dart';
import '../../../domain/technique/squat_state.dart';

enum CameraStatus { initializing, ready, permissionDenied, noCamera, failed }

class PoseOverlay {
  const PoseOverlay({required this.frame, required this.uprightSize});
  final PoseFrame frame;
  final Size uprightSize;
}

class PerfStats {
  const PerfStats({
    this.cameraFps = 0,
    this.poseFps = 0,
    this.latencyMs = 0,
    this.avgLatencyMs = 0,
    this.droppedFrames = 0,
    this.imageSize,
  });

  /// Кадров в секунду приходит с камеры.
  final double cameraFps;

  /// Кадров в секунду реально прошло через ML Kit.
  final double poseFps;

  /// Конвертация + детекция последнего кадра.
  final double latencyMs;
  final double avgLatencyMs;

  /// Кадры, пропущенные из-за того, что предыдущий ещё обрабатывался.
  final int droppedFrames;
  final Size? imageSize;
}

const _resolutionPresets = [
  ResolutionPreset.low,
  ResolutionPreset.medium,
  ResolutionPreset.high,
];

const _permissionErrorCodes = {
  'CameraAccessDenied',
  'CameraAccessDeniedWithoutPrompt',
  'CameraAccessRestricted',
};

class CameraWorkoutViewModel extends ChangeNotifier {
  CameraWorkoutViewModel({
    required this.exerciseId,
    this.targetReps = 12,
    SquatConfig squatConfig = const SquatConfig(),
  }) : analyzer = SquatAnalyzer(config: squatConfig);

  final String exerciseId;
  final int targetReps;
  final SquatAnalyzer analyzer;

  bool get isExerciseSupported => exerciseId == 'squat';

  final squat = ValueNotifier<SquatState>(const SquatState());
  final pose = ValueNotifier<PoseOverlay?>(null);
  final perf = ValueNotifier<PerfStats>(const PerfStats());

  CameraStatus _status = CameraStatus.initializing;
  CameraStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CameraController? _controller;
  CameraController? get controller => _controller;

  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool get canSwitchCamera => _cameras.length > 1;
  CameraLensDirection? get lensDirection =>
      _cameras.isEmpty ? null : _cameras[_cameraIndex].lensDirection;

  ResolutionPreset _resolution = ResolutionPreset.medium;
  ResolutionPreset get resolution => _resolution;

  PoseDetectorService _detector = PoseDetectorService();
  PoseDetectionModel get model => _detector.model;

  bool _showDebug = true;
  bool get showDebug => _showDebug;

  bool _running = true;
  bool get running => _running;

  bool _isProcessing = false;
  bool _starting = false;
  bool _wasBackgrounded = false;
  bool _disposed = false;
  final _session = Stopwatch()..start();
  final _cameraFrameTimes = Queue<int>();
  final _poseFrameTimes = Queue<int>();
  int _droppedFrames = 0;
  double _avgLatencyMs = 0;

  Future<void> init() async {
    _setStatus(CameraStatus.initializing);
    try {
      _cameras = await availableCameras();
    } on CameraException catch (e) {
      _handleCameraException(e);
      return;
    }
    if (_cameras.isEmpty) {
      _setStatus(CameraStatus.noCamera);
      return;
    }
    final front = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    _cameraIndex = front >= 0 ? front : 0;
    await _startCamera();
  }

  Future<void> switchCamera() async {
    if (!canSwitchCamera) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    pose.value = null;
    await _restartCamera();
  }

  Future<void> cycleResolution() async {
    final next =
        (_resolutionPresets.indexOf(_resolution) + 1) %
        _resolutionPresets.length;
    _resolution = _resolutionPresets[next];
    await _restartCamera();
  }

  Future<void> toggleModel() async {
    final old = _detector;
    _detector = PoseDetectorService(
      model: old.model == PoseDetectionModel.base
          ? PoseDetectionModel.accurate
          : PoseDetectionModel.base,
    );
    _resetPerf();
    _notify();
    await old.close();
  }

  void toggleDebug() {
    _showDebug = !_showDebug;
    _notify();
  }

  void toggleRunning() {
    _running = !_running;
    _notify();
  }

  /// Приложение неактивно/в фоне — камеру надо отпустить.
  /// [backgrounded] — реально ушли в фон (например, в настройки), а не просто
  /// системный диалог разрешения поверх приложения.
  Future<void> suspend({bool backgrounded = false}) async {
    if (backgrounded) _wasBackgrounded = true;
    final controller = _controller;
    if (controller == null) return;
    _controller = null;
    _notify();
    await _disposeController(controller);
  }

  /// Вернулись из фона (в том числе из настроек, где могли выдать доступ).
  Future<void> resume() async {
    final wasBackgrounded = _wasBackgrounded;
    _wasBackgrounded = false;
    if (_status == CameraStatus.permissionDenied) {
      if (wasBackgrounded) await init();
      return;
    }
    if (_controller != null || _cameras.isEmpty) return;
    await _startCamera();
  }

  Future<void> _restartCamera() async {
    final controller = _controller;
    _controller = null;
    _notify();
    await _disposeController(controller);
    await _startCamera();
  }

  Future<void> _startCamera() async {
    if (_starting || _disposed) return;
    _starting = true;
    try {
      await _startCameraUnguarded();
    } finally {
      _starting = false;
    }
  }

  Future<void> _startCameraUnguarded() async {
    final camera = _cameras[_cameraIndex];
    final controller = CameraController(
      camera,
      _resolution,
      enableAudio: false,
      imageFormatGroup: mlKitImageFormatGroup,
    );
    try {
      await controller.initialize();
      if (_disposed) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      await controller.startImageStream(
        (image) => _onCameraImage(image, controller),
      );
    } on CameraException catch (e) {
      if (identical(_controller, controller)) _controller = null;
      await controller.dispose();
      _handleCameraException(e);
      return;
    }
    if (_disposed) return;
    _resetPerf();
    _setStatus(CameraStatus.ready);
  }

  Future<void> _onCameraImage(
    CameraImage image,
    CameraController source,
  ) async {
    if (_disposed || !identical(source, _controller)) return;
    final now = _session.elapsedMicroseconds;
    _pushRate(_cameraFrameTimes, now);

    // Throttle: пока ML Kit занят предыдущим кадром, новые выбрасываем.
    if (_isProcessing || !_running) {
      if (_isProcessing) _droppedFrames++;
      return;
    }
    _isProcessing = true;
    try {
      await _processImage(image, source, now);
    } on PlatformException catch (e) {
      debugPrint('Pose detection failed: ${e.code} ${e.message}');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processImage(
    CameraImage image,
    CameraController source,
    int startedAtUs,
  ) async {
    final camera = source.description;
    final rotation = inputImageRotation(camera, source.value.deviceOrientation);
    if (rotation == null) return;
    final inputImage = inputImageFromCameraImage(image, rotation);
    if (inputImage == null) return;

    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final geometry = FrameGeometry.from(
      imageSize: imageSize,
      rotation: rotation,
      lensDirection: camera.lensDirection,
    );
    final frame = await _detector.detect(
      inputImage,
      geometry,
      Duration(microseconds: startedAtUs),
    );
    if (_disposed || !identical(source, _controller)) return;

    final finishedAt = _session.elapsedMicroseconds;
    final latencyMs = (finishedAt - startedAtUs) / 1000;
    _avgLatencyMs = _avgLatencyMs == 0
        ? latencyMs
        : _avgLatencyMs * 0.9 + latencyMs * 0.1;
    _pushRate(_poseFrameTimes, finishedAt);

    if (frame == null) {
      pose.value = null;
      squat.value = squat.value.copyWith(poseVisible: false);
    } else {
      pose.value = PoseOverlay(frame: frame, uprightSize: geometry.uprightSize);
      if (isExerciseSupported) squat.value = analyzer.process(frame);
    }

    perf.value = PerfStats(
      cameraFps: _rate(_cameraFrameTimes),
      poseFps: _rate(_poseFrameTimes),
      latencyMs: latencyMs,
      avgLatencyMs: _avgLatencyMs,
      droppedFrames: _droppedFrames,
      imageSize: imageSize,
    );
  }

  /// Храним метки времени за последнюю секунду.
  void _pushRate(Queue<int> times, int nowUs) {
    times.addLast(nowUs);
    while (times.isNotEmpty && nowUs - times.first > 1000000) {
      times.removeFirst();
    }
  }

  double _rate(Queue<int> times) {
    if (times.length < 2) return 0;
    final spanUs = times.last - times.first;
    if (spanUs == 0) return 0;
    return (times.length - 1) * 1e6 / spanUs;
  }

  void _resetPerf() {
    _cameraFrameTimes.clear();
    _poseFrameTimes.clear();
    _droppedFrames = 0;
    _avgLatencyMs = 0;
    perf.value = const PerfStats();
  }

  void _handleCameraException(CameraException e) {
    if (_permissionErrorCodes.contains(e.code)) {
      _setStatus(CameraStatus.permissionDenied);
    } else {
      _errorMessage = '${e.code}: ${e.description ?? ''}';
      _setStatus(CameraStatus.failed);
    }
  }

  void _setStatus(CameraStatus status) {
    _status = status;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _disposeController(CameraController? controller) async {
    if (controller == null) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } on CameraException catch (e) {
      debugPrint('stopImageStream failed: ${e.code}');
    }
    await controller.dispose();
  }

  @override
  void dispose() {
    _disposed = true;
    final controller = _controller;
    _controller = null;
    unawaited(
      _disposeController(controller).whenComplete(() => _detector.close()),
    );
    unawaited(analyzer.dispose());
    squat.dispose();
    pose.dispose();
    perf.dispose();
    super.dispose();
  }
}
