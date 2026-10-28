import 'dart:async';
import 'dart:math' as math;

import 'geometry.dart';
import 'pose_frame.dart';
import 'squat_config.dart';
import 'squat_state.dart';

/// Счётчик приседаний + детекторы ошибок. Чистый Dart: на вход — кадры позы,
/// на выход — [SquatState] и поток [events].
///
/// Повтор: стоя (> standingAngle) → вниз ниже bottomAngle → снова выше
/// standingAngle. Зазор между порогами — гистерезис, дребезг у порога
/// не даёт лишних повторов.
class SquatAnalyzer {
  SquatAnalyzer({this.config = const SquatConfig()});

  final SquatConfig config;

  final _events = StreamController<TechniqueEvent>.broadcast(sync: true);
  Stream<TechniqueEvent> get events => _events.stream;

  SquatState _state = const SquatState();
  SquatState get state => _state;

  double? _smoothedAngle;
  double _repMinAngle = double.infinity;
  bool _repHadError = false;
  int _valgusFrames = 0;
  bool _kneesIn = false;
  Duration? _shallowErrorUntil;

  void reset() {
    _state = const SquatState();
    _smoothedAngle = null;
    _repMinAngle = double.infinity;
    _repHadError = false;
    _valgusFrames = 0;
    _kneesIn = false;
    _shallowErrorUntil = null;
  }

  SquatState process(PoseFrame frame) {
    final rawAngle = _kneeAngle(frame);
    if (rawAngle == null) {
      _state = _state.copyWith(
        poseVisible: false,
        activeError: () => _activeError(frame.timestamp),
      );
      return _state;
    }

    final previous = _smoothedAngle;
    final angle = previous == null
        ? rawAngle
        : previous + config.angleSmoothing * (rawAngle - previous);
    _smoothedAngle = angle;

    var reps = _state.reps;
    var repsWithErrors = _state.repsWithErrors;
    final errorCounts = Map<TechniqueError, int>.of(_state.errorCounts);
    var phase = _state.phase;

    void raise(TechniqueError error) {
      errorCounts[error] = (errorCounts[error] ?? 0) + 1;
      _repHadError = true;
      _events.add(TechniqueErrorRaised(frame.timestamp, error));
    }

    switch (phase) {
      case SquatPhase.notReady:
        if (angle > config.standingAngle) phase = SquatPhase.standing;
      case SquatPhase.standing:
        if (angle < config.standingAngle) {
          phase = SquatPhase.descending;
          _repMinAngle = angle;
          _repHadError = false;
        }
      case SquatPhase.descending:
        _repMinAngle = math.min(_repMinAngle, angle);
        if (angle < config.bottomAngle) {
          phase = SquatPhase.bottom;
          _shallowErrorUntil = null;
        } else if (angle > config.standingAngle) {
          phase = SquatPhase.standing;
          if (_repMinAngle < config.shallowRepAngle) {
            _shallowErrorUntil = frame.timestamp + config.errorHold;
            raise(TechniqueError.notDeepEnough);
          }
        }
      case SquatPhase.bottom:
      case SquatPhase.ascending:
        _repMinAngle = math.min(_repMinAngle, angle);
        if (angle < config.bottomAngle) {
          phase = SquatPhase.bottom;
        } else if (angle > config.standingAngle) {
          phase = SquatPhase.standing;
          reps++;
          if (_repHadError) repsWithErrors++;
          _events.add(
            RepCompleted(
              frame.timestamp,
              reps: reps,
              minAngle: _repMinAngle,
              hadError: _repHadError,
            ),
          );
        } else {
          phase = SquatPhase.ascending;
        }
    }

    final kneesInStarted = _updateValgus(frame, angle, phase);
    if (kneesInStarted) raise(TechniqueError.kneesIn);

    _state = SquatState(
      reps: reps,
      currentAngle: angle,
      phase: phase,
      activeError: _activeError(frame.timestamp),
      poseVisible: true,
      repsWithErrors: repsWithErrors,
      errorCounts: errorCounts,
    );
    return _state;
  }

  Future<void> dispose() => _events.close();

  TechniqueError? _activeError(Duration now) {
    if (_kneesIn) return TechniqueError.kneesIn;
    final until = _shallowErrorUntil;
    if (until != null && now <= until) return TechniqueError.notDeepEnough;
    return null;
  }

  /// Средний угол по ногам с уверенными точками; null — ни одной ноги не видно.
  double? _kneeAngle(PoseFrame frame) {
    final angles = <double>[];
    for (final (hip, knee, ankle) in const [
      (BodyLandmark.leftHip, BodyLandmark.leftKnee, BodyLandmark.leftAnkle),
      (BodyLandmark.rightHip, BodyLandmark.rightKnee, BodyLandmark.rightAnkle),
    ]) {
      final h = frame.confident(hip, config.minLandmarkLikelihood);
      final k = frame.confident(knee, config.minLandmarkLikelihood);
      final a = frame.confident(ankle, config.minLandmarkLikelihood);
      if (h == null || k == null || a == null) continue;
      final angle = jointAngleDegrees(h, k, a);
      if (!angle.isNaN) angles.add(angle);
    }
    if (angles.isEmpty) return null;
    return angles.reduce((a, b) => a + b) / angles.length;
  }

  /// Возвращает true в кадре, где ошибка kneesIn только что поднялась.
  bool _updateValgus(PoseFrame frame, double angle, SquatPhase phase) {
    final inSquat =
        phase != SquatPhase.standing &&
        phase != SquatPhase.notReady &&
        angle < config.valgusMaxKneeAngle;
    final ratio = inSquat ? _kneeToAnkleRatio(frame) : null;

    if (ratio == null) {
      _valgusFrames = 0;
      _kneesIn = false;
      return false;
    }
    if (ratio < config.valgusRatio) {
      _valgusFrames++;
      if (!_kneesIn && _valgusFrames >= config.valgusMinFrames) {
        _kneesIn = true;
        return true;
      }
    } else if (ratio > config.valgusClearRatio) {
      _valgusFrames = 0;
      _kneesIn = false;
    }
    return false;
  }

  double? _kneeToAnkleRatio(PoseFrame frame) {
    final min = config.minLandmarkLikelihood;
    final leftKnee = frame.confident(BodyLandmark.leftKnee, min);
    final rightKnee = frame.confident(BodyLandmark.rightKnee, min);
    final leftAnkle = frame.confident(BodyLandmark.leftAnkle, min);
    final rightAnkle = frame.confident(BodyLandmark.rightAnkle, min);
    final leftShoulder = frame.confident(BodyLandmark.leftShoulder, min);
    final rightShoulder = frame.confident(BodyLandmark.rightShoulder, min);
    final leftHip = frame.confident(BodyLandmark.leftHip, min);
    final rightHip = frame.confident(BodyLandmark.rightHip, min);
    if (leftKnee == null ||
        rightKnee == null ||
        leftAnkle == null ||
        rightAnkle == null ||
        leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return null;
    }

    final torso = distance(
      midpoint(leftShoulder, rightShoulder),
      midpoint(leftHip, rightHip),
    );
    final ankleSpread = (leftAnkle.x - rightAnkle.x).abs();
    if (torso == 0 || ankleSpread / torso < config.frontalViewMinAnkleToTorso) {
      return null;
    }

    return (leftKnee.x - rightKnee.x).abs() / ankleSpread;
  }
}
