import 'dart:convert';
import 'dart:io';

import 'package:ai_sport/domain/models/onboarding.dart';
import 'package:ai_sport/domain/models/training_plan.dart';
import 'package:ai_sport/domain/plans/plan_rules.dart';
import 'package:ai_sport/domain/plans/plan_template.dart';
import 'package:flutter_test/flutter_test.dart';

import 'plan_test_data.dart';

List<PlanTemplate> shippedTemplates() => [
  for (final file in Directory('assets/plans').listSync().whereType<File>())
    if (file.path.endsWith('.json') && !file.path.endsWith('.schema.json'))
      PlanTemplate.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      ),
];

PlanExercise exercise(TrainingPlan plan, String id) =>
    plan.startingExercises.firstWhere((e) => e.exerciseId == id);

void main() {
  group('PlanRules.levelFor', () {
    test('weak calibration → beginner even with long experience', () {
      expect(
        PlanRules.levelFor(Experience.over2Years, calibration()),
        PlanLevel.beginner,
      );
    });

    test('mid calibration → intermediate', () {
      final c = calibration(
        squats: 30,
        pushups: 10,
        variant: PushupVariant.floor,
        plank: 60,
      );
      expect(
        PlanRules.levelFor(Experience.from6To24Months, c),
        PlanLevel.intermediate,
      );
    });

    test('strong calibration + experience → advanced', () {
      final c = calibration(
        squats: 45,
        pushups: 25,
        variant: PushupVariant.floor,
        plank: 100,
      );
      expect(PlanRules.levelFor(Experience.over2Years, c), PlanLevel.advanced);
    });

    test('no experience caps level at intermediate', () {
      final c = calibration(
        squats: 45,
        pushups: 25,
        variant: PushupVariant.floor,
        plank: 100,
      );
      expect(PlanRules.levelFor(Experience.none, c), PlanLevel.intermediate);
    });

    test('knees pushups count as half for level', () {
      final floor = calibration(
        squats: 30,
        pushups: 20,
        variant: PushupVariant.floor,
        plank: 100,
      );
      final knees = calibration(
        squats: 30,
        pushups: 20,
        variant: PushupVariant.knees,
        plank: 100,
      );
      expect(
        PlanRules.levelFor(Experience.over2Years, floor),
        PlanLevel.advanced,
      );
      expect(
        PlanRules.levelFor(Experience.over2Years, knees),
        PlanLevel.intermediate,
      );
    });

    test('difficulty ≥ 8 lowers, ≤ 3 raises, never below beginner', () {
      final mid = calibration(
        squats: 30,
        pushups: 10,
        variant: PushupVariant.floor,
        plank: 60,
      );
      final exp = Experience.over2Years;
      expect(PlanRules.levelFor(exp, mid), PlanLevel.intermediate);
      expect(
        PlanRules.levelFor(
          exp,
          calibration(
            squats: 30,
            pushups: 10,
            variant: PushupVariant.floor,
            plank: 60,
            difficulty: 8,
          ),
        ),
        PlanLevel.beginner,
      );
      expect(
        PlanRules.levelFor(
          exp,
          calibration(
            squats: 30,
            pushups: 10,
            variant: PushupVariant.floor,
            plank: 60,
            difficulty: 3,
          ),
        ),
        PlanLevel.advanced,
      );
      expect(
        PlanRules.levelFor(exp, calibration(difficulty: 10)),
        PlanLevel.beginner,
      );
    });
  });

  group('PlanRules.build with shipped templates', () {
    final templates = shippedTemplates();

    test(
      'mockup persona: 8 недель / 3× / 30 мин, приседания 3×12, с колен 3×6',
      () {
        final plan = PlanRules.build(templates, answers());
        expect(plan.templateId, 'tone-beginner');
        expect(plan.level, PlanLevel.beginner);
        expect(
          (plan.weeks, plan.sessionsPerWeek, plan.minutesPerSession),
          (8, 3, 30),
        );
        final squat = exercise(plan, 'squat');
        expect((squat.sets, squat.reps), (3, 12));
        final pushup = exercise(plan, 'pushup_knees');
        expect(
          (pushup.title, pushup.sets, pushup.reps),
          ('Отжимания с колен', 3, 6),
        );
        expect(exercise(plan, 'plank').holdSeconds, 30);
      },
    );

    test('beginner, tone, 2 days → tone-beginner, 2 sessions', () {
      final plan = PlanRules.build(
        templates,
        answers(goals: {Goal.tone, Goal.loseWeight}, days: 2, minutes: 15),
      );
      expect(plan.templateId, 'tone-beginner');
      expect(plan.sessionsPerWeek, 2);
      expect(plan.minutesPerSession, 15);
    });

    test('experienced, strength, 4 days → strength-advanced', () {
      final plan = PlanRules.build(
        templates,
        answers(
          goals: {Goal.getStronger},
          experience: Experience.over2Years,
          days: 4,
          minutes: 60,
          calib: calibration(
            squats: 45,
            pushups: 25,
            variant: PushupVariant.floor,
            plank: 100,
          ),
        ),
      );
      expect(plan.templateId, 'strength-advanced');
      expect(plan.level, PlanLevel.advanced);
      expect((plan.sessionsPerWeek, plan.minutesPerSession), (4, 60));
      final pushup = exercise(plan, 'pushup');
      expect(pushup.title, 'Отжимания');
      expect((pushup.sets, pushup.reps), (5, 18));
      expect(exercise(plan, 'squat').reps, 23);
      expect(exercise(plan, 'plank').holdSeconds, 80);
    });

    test(
      'intermediate fat loss → fat-loss-intermediate with intermediate sets',
      () {
        final plan = PlanRules.build(
          templates,
          answers(
            goals: {Goal.loseWeight},
            experience: Experience.from6To24Months,
            days: 4,
            minutes: 45,
            calib: calibration(
              squats: 30,
              pushups: 10,
              variant: PushupVariant.floor,
              plank: 60,
            ),
          ),
        );
        expect(plan.templateId, 'fat-loss-intermediate');
        expect(exercise(plan, 'squat').sets, 3);
      },
    );

    test('difficulty 9 lowers level and dose', () {
      CalibrationResult strong(int difficulty) => calibration(
        squats: 45,
        pushups: 25,
        variant: PushupVariant.floor,
        plank: 100,
        difficulty: difficulty,
      );
      TrainingPlan planFor(int difficulty) => PlanRules.build(
        templates,
        answers(
          goals: {Goal.getStronger},
          experience: Experience.over2Years,
          days: 4,
          minutes: 60,
          calib: strong(difficulty),
        ),
      );

      final normal = planFor(5);
      final hard = planFor(9);
      expect(hard.level, PlanLevel.intermediate);
      expect(hard.templateId, 'strength-intermediate');
      expect(
        exercise(hard, 'squat').sets,
        lessThan(exercise(normal, 'squat').sets),
      );
      expect(
        exercise(hard, 'squat').reps,
        lessThan(exercise(normal, 'squat').reps!),
      );
      expect(
        exercise(hard, 'pushup').reps,
        lessThan(exercise(normal, 'pushup').reps!),
      );
    });

    test('difficulty 9 lowers dose even when level is already beginner', () {
      final hard = PlanRules.build(
        templates,
        answers(calib: calibration(difficulty: 9)),
      );
      expect(hard.level, PlanLevel.beginner);
      expect(exercise(hard, 'squat').reps, 10);
    });

    test(
      'floor pushups below threshold → knees variant, dose from 2× reps',
      () {
        final plan = PlanRules.build(
          templates,
          answers(calib: calibration(pushups: 3, variant: PushupVariant.floor)),
        );
        final pushup = exercise(plan, 'pushup_knees');
        expect(pushup.title, 'Отжимания с колен');
        expect(pushup.reps, 4);
        expect(
          plan.startingExercises.any((e) => e.exerciseId == 'pushup'),
          isFalse,
        );
      },
    );

    test('floor pushups at threshold stay on floor', () {
      final plan = PlanRules.build(
        templates,
        answers(calib: calibration(pushups: 6, variant: PushupVariant.floor)),
      );
      expect(exercise(plan, 'pushup').reps, 4);
    });

    test('result does not depend on template order', () {
      final input = answers(days: 5, goals: {Goal.endurance});
      final ids = {
        PlanRules.build(templates, input).templateId,
        PlanRules.build(templates.reversed.toList(), input).templateId,
      };
      expect(ids, hasLength(1));
    });
  });

  group('PlanRules selection details', () {
    test('ties broken by id alphabetically regardless of order', () {
      final list = [template('b-plan'), template('a-plan')];
      expect(PlanRules.build(list, answers()).templateId, 'a-plan');
      expect(
        PlanRules.build(list.reversed.toList(), answers()).templateId,
        'a-plan',
      );
    });

    test('more goal overlap wins', () {
      final list = [
        template('a-one', goals: ['tone']),
        template('b-two', goals: ['tone', 'loseWeight']),
      ];
      final plan = PlanRules.build(
        list,
        answers(goals: {Goal.tone, Goal.loseWeight}),
      );
      expect(plan.templateId, 'b-two');
    });

    test('days closer to user wins over goals of equal count', () {
      final list = [
        template('a-few', sessions: [2]),
        template('b-many', sessions: [4, 5]),
      ];
      expect(PlanRules.build(list, answers(days: 5)).templateId, 'b-many');
    });

    test('level beats goals; falls back to nearest level', () {
      final list = [
        template('a-adv', levels: ['advanced'], goals: ['tone']),
        template('b-int', levels: ['intermediate'], goals: ['gainMass']),
      ];
      expect(PlanRules.build(list, answers()).templateId, 'b-int');
    });

    test('sessions capped by template max', () {
      final plan = PlanRules.build([
        template('a', sessions: [2, 3]),
      ], answers(days: 5));
      expect(plan.sessionsPerWeek, 3);
    });
  });

  group('PlanRules StateError', () {
    test('screening with any "yes"', () {
      final failed = passedScreening().answer(0, true);
      expect(
        () => PlanRules.build([template('a')], answers(screening: failed)),
        throwsStateError,
      );
    });

    test('incomplete screening', () {
      expect(
        () => PlanRules.build([
          template('a'),
        ], answers(screening: ScreeningAnswers())),
        throwsStateError,
      );
    });

    test('no calibration', () {
      final noCalib = OnboardingAnswers(
        screening: passedScreening(),
        goals: {Goal.tone},
        daysPerWeek: 3,
      );
      expect(() => PlanRules.build([template('a')], noCalib), throwsStateError);
    });

    test('no templates', () {
      expect(() => PlanRules.build([], answers()), throwsStateError);
    });
  });
}
