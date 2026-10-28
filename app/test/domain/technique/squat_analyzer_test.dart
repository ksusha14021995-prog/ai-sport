import 'package:ai_sport/domain/technique/geometry.dart';
import 'package:ai_sport/domain/technique/pose_frame.dart';
import 'package:ai_sport/domain/technique/squat_analyzer.dart';
import 'package:ai_sport/domain/technique/squat_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'synthetic_pose.dart';

void main() {
  group('jointAngleDegrees', () {
    test('right angle is 90', () {
      expect(
        jointAngleDegrees(
          const Landmark(0, -1),
          const Landmark(0, 0),
          const Landmark(1, 0),
        ),
        closeTo(90, 1e-9),
      );
    });

    test('straight leg is 180', () {
      expect(
        jointAngleDegrees(
          const Landmark(0, -1),
          const Landmark(0, 0),
          const Landmark(0, 1),
        ),
        closeTo(180, 1e-9),
      );
    });

    test('degenerate points give NaN', () {
      expect(
        jointAngleDegrees(
          const Landmark(0, 0),
          const Landmark(0, 0),
          const Landmark(0, 1),
        ).isNaN,
        isTrue,
      );
    });

    test('synthetic pose produces requested knee angle', () {
      for (final angle in [175.0, 120.0, 90.0, 60.0]) {
        final pose = syntheticSquatPose(angle, kneeHalfSpread: 30);
        final measured = jointAngleDegrees(
          pose[BodyLandmark.leftHip]!,
          pose[BodyLandmark.leftKnee]!,
          pose[BodyLandmark.leftAnkle]!,
        );
        expect(measured, closeTo(angle, 1e-6));
      }
    });
  });

  group('SquatAnalyzer', () {
    late SquatAnalyzer analyzer;
    late List<TechniqueEvent> events;

    setUp(() {
      analyzer = SquatAnalyzer();
      events = [];
      analyzer.events.listen(events.add);
    });

    tearDown(() => analyzer.dispose());

    SquatState run(FrameSequence sequence) {
      for (final frame in sequence.frames) {
        analyzer.process(frame);
      }
      return analyzer.state;
    }

    test('full rep is counted once', () {
      final state = run(FrameSequence()..rep());

      expect(state.reps, 1);
      expect(state.phase, SquatPhase.standing);
      expect(state.activeError, isNull);
      expect(state.repsWithErrors, 0);
      expect(events.whereType<RepCompleted>().single.minAngle, lessThan(100));
    });

    test('three reps are counted three times', () {
      final state = run(
        FrameSequence()
          ..rep()
          ..rep()
          ..rep(),
      );
      expect(state.reps, 3);
    });

    test('half rep is not counted and flagged as not deep enough', () {
      final sequence = FrameSequence()
        ..hold(175, 5)
        ..sweep(175, 120)
        ..sweep(120, 175)
        ..hold(175, 3);
      final state = run(sequence);

      expect(state.reps, 0);
      expect(state.activeError, TechniqueError.notDeepEnough);
      expect(
        events.whereType<TechniqueErrorRaised>().single.error,
        TechniqueError.notDeepEnough,
      );
    });

    test('not-deep-enough hint expires after errorHold', () {
      final sequence = FrameSequence()
        ..hold(175, 5)
        ..sweep(175, 120)
        ..sweep(120, 175)
        ..hold(175, 30 * 3);
      expect(run(sequence).activeError, isNull);
    });

    test('small wobble at the top is neither a rep nor an error', () {
      final sequence = FrameSequence()
        ..hold(175, 5)
        ..sweep(175, 150)
        ..sweep(150, 175);
      final state = run(sequence);
      expect(state.reps, 0);
      expect(events, isEmpty);
    });

    test('jitter around both thresholds is not double-counted', () {
      final sequence = FrameSequence()
        ..hold(175, 5)
        ..sweep(175, 95);
      for (var i = 0; i < 20; i++) {
        sequence.add(i.isEven ? 92 : 108);
      }
      sequence.sweep(108, 160);
      for (var i = 0; i < 20; i++) {
        sequence.add(i.isEven ? 168 : 152);
      }
      sequence.hold(175, 5);

      final state = run(sequence);
      expect(state.reps, 1);
      expect(events.whereType<TechniqueErrorRaised>(), isEmpty);
    });

    test('starting in a squat does not count until standing is seen', () {
      final sequence = FrameSequence()
        ..hold(85, 5)
        ..sweep(85, 175)
        ..hold(175, 5);
      final state = run(sequence);
      expect(state.reps, 0);
      expect(state.phase, SquatPhase.standing);
    });

    test('knees caving in at the bottom raise kneesIn', () {
      final sequence = FrameSequence()
        ..hold(175, 5)
        ..sweep(175, 80)
        ..hold(80, 6, kneeHalfSpread: 25);
      final atBottom = run(sequence);

      expect(atBottom.activeError, TechniqueError.kneesIn);
      expect(atBottom.errorCounts[TechniqueError.kneesIn], 1);
      expect(
        events.whereType<TechniqueErrorRaised>().single.error,
        TechniqueError.kneesIn,
      );

      final finished = run(
        FrameSequence()
          ..sweep(80, 175)
          ..hold(175, 5),
      );
      expect(finished.reps, 1);
      expect(finished.repsWithErrors, 1);
      expect(finished.activeError, isNull);
      expect(events.whereType<RepCompleted>().single.hadError, isTrue);
    });

    test('single valgus frame is not enough to flag', () {
      final sequence = FrameSequence()
        ..hold(175, 5)
        ..sweep(175, 80)
        ..add(80, kneeHalfSpread: 25)
        ..hold(80, 5);
      expect(run(sequence).activeError, isNull);
    });

    test('valgus is ignored in side view (ankles close together)', () {
      final sequence = FrameSequence()..hold(175, 5);
      for (var i = 0; i < 10; i++) {
        sequence.add(175 - i * 10.0, kneeHalfSpread: 5, ankleHalfSpread: 15);
      }
      expect(run(sequence).activeError, isNull);
    });

    test('low-confidence frames are ignored', () {
      final state = run(FrameSequence()..rep(likelihood: 0.2));
      expect(state.reps, 0);
      expect(state.poseVisible, isFalse);
      expect(state.currentAngle, isNull);
      expect(state.phase, SquatPhase.notReady);
    });

    test(
      'low-confidence garbage in the middle of a rep does not break counting',
      () {
        final sequence = FrameSequence()
          ..hold(175, 5)
          ..sweep(175, 80);
        sequence.hold(178, 4, likelihood: 0.1);
        sequence
          ..hold(80, 3)
          ..sweep(80, 175)
          ..hold(175, 5);
        final state = run(sequence);
        expect(state.reps, 1);
        expect(state.poseVisible, isTrue);
      },
    );

    test('one confident leg is enough to count', () {
      final sequence = FrameSequence()..rep();
      for (final frame in sequence.frames) {
        final landmarks = Map.of(frame.landmarks)
          ..[BodyLandmark.rightKnee] = const Landmark(0, 0, likelihood: 0.1);
        analyzer.process(
          PoseFrame(landmarks: landmarks, timestamp: frame.timestamp),
        );
      }
      expect(analyzer.state.reps, 1);
    });

    test('reset clears counters', () {
      run(FrameSequence()..rep());
      analyzer.reset();
      expect(analyzer.state.reps, 0);
      expect(analyzer.state.phase, SquatPhase.notReady);
    });
  });
}
