import 'package:ai_sport/domain/models/onboarding.dart';
import 'package:ai_sport/domain/models/training_plan.dart';
import 'package:ai_sport/domain/plans/plan_template.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> validJson() => {
  'id': 'demo',
  'title': 'Демо',
  'goals': ['tone', 'endurance'],
  'levels': ['intermediate', 'advanced'],
  'experience': {'from': 'under6Months', 'to': 'over2Years'},
  'sessionsPerWeek': [4, 3],
  'minutesPerSession': [30],
  'weeks': 8,
  'progression': 'текст',
  'exercises': [
    {
      'exerciseId': 'squat',
      'title': 'Приседания',
      'sets': {'intermediate': 3, 'advanced': 4},
      'reps': {'from': 'squatReps', 'factor': 0.5, 'min': 8, 'max': 20},
    },
    {'exerciseId': 'plank', 'title': 'Планка', 'sets': 3, 'holdSeconds': 30},
  ],
};

Map<String, dynamic> withExercise(Map<String, dynamic> exercise) =>
    validJson()..['exercises'] = [exercise];

void main() {
  group('PlanTemplate.fromJson', () {
    test('parses all fields', () {
      final t = PlanTemplate.fromJson(validJson());
      expect(t.goals, {Goal.tone, Goal.endurance});
      expect(t.levels, {PlanLevel.intermediate, PlanLevel.advanced});
      expect(t.sessionsPerWeek, [3, 4]);
      expect(t.fitsExperience(Experience.none), isFalse);
      expect(t.fitsExperience(Experience.from6To24Months), isTrue);
      expect(t.exercises.first.reps, isA<CalibrationDose>());
      expect(t.exercises.last.holdSeconds, isA<FixedDose>());
    });

    test('toJson round-trips', () {
      final t = PlanTemplate.fromJson(validJson());
      expect(PlanTemplate.fromJson(t.toJson()).toJson(), t.toJson());
    });

    test(
      'sets: single number applies to every level, map falls back to nearest',
      () {
        final t = PlanTemplate.fromJson(validJson());
        expect(t.exercises.last.setsFor(PlanLevel.beginner), 3);
        expect(t.exercises.first.setsFor(PlanLevel.advanced), 4);
        expect(t.exercises.first.setsFor(PlanLevel.beginner), 3);
      },
    );

    final invalid = <String, Map<String, dynamic>>{
      'unknown goal': validJson()..['goals'] = ['fly'],
      'empty levels': validJson()..['levels'] = <String>[],
      'experience from > to': validJson()
        ..['experience'] = {'from': 'over2Years', 'to': 'none'},
      'sessions outside 2..5': validJson()..['sessionsPerWeek'] = [7],
      'minutes outside options': validJson()..['minutesPerSession'] = [20],
      'zero weeks': validJson()..['weeks'] = 0,
      'no exercises': validJson()..['exercises'] = <Object>[],
      'missing title': validJson()..remove('title'),
      'both reps and hold': withExercise({
        'exerciseId': 'plank',
        'title': 'x',
        'sets': 3,
        'reps': 10,
        'holdSeconds': 30,
      }),
      'neither reps nor hold': withExercise({
        'exerciseId': 'plank',
        'title': 'x',
        'sets': 3,
      }),
      'min > max': withExercise({
        'exerciseId': 'squat',
        'title': 'x',
        'sets': 3,
        'reps': {'from': 'squatReps', 'factor': 0.5, 'min': 20, 'max': 8},
      }),
      'unknown metric': withExercise({
        'exerciseId': 'squat',
        'title': 'x',
        'sets': 3,
        'reps': {'from': 'jumps', 'factor': 0.5, 'min': 8, 'max': 20},
      }),
      'unknown level in sets': withExercise({
        'exerciseId': 'squat',
        'title': 'x',
        'sets': {'pro': 3},
        'reps': 10,
      }),
      'duplicate exerciseId': validJson()
        ..['exercises'] = [
          for (var i = 0; i < 2; i++)
            {'exerciseId': 'squat', 'title': 'x', 'sets': 3, 'reps': 10},
        ],
    };
    for (final MapEntry(key: name, value: json) in invalid.entries) {
      test('rejects $name', () {
        expect(() => PlanTemplate.fromJson(json), throwsFormatException);
      });
    }
  });
}
