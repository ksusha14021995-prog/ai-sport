import '../models/onboarding.dart';
import '../models/training_plan.dart';

/// Показатель калибровки, от которого считается стартовая норма.
enum CalibrationMetric { squatReps, pushupReps, plankSeconds }

/// Норма в шаблоне: либо фиксированное число, либо доля от результата калибровки.
sealed class DoseRule {
  const DoseRule();

  factory DoseRule.fromJson(Object? json, String field) => switch (json) {
    int value when value > 0 => FixedDose(value),
    {'from': String from, 'factor': num factor, 'min': int min, 'max': int max}
        when factor > 0 && min > 0 && min <= max =>
      CalibrationDose(
        from: _parseEnum(CalibrationMetric.values, from, '$field.from'),
        factor: factor.toDouble(),
        min: min,
        max: max,
      ),
    _ => throw FormatException(
      '$field: ожидается положительное число или '
      '{from, factor > 0, min > 0, max >= min}, получено $json',
    ),
  };

  Object toJson();
}

class FixedDose extends DoseRule {
  final int value;

  const FixedDose(this.value);

  @override
  Object toJson() => value;
}

class CalibrationDose extends DoseRule {
  final CalibrationMetric from;
  final double factor;
  final int min;
  final int max;

  const CalibrationDose({
    required this.from,
    required this.factor,
    required this.min,
    required this.max,
  });

  @override
  Object toJson() => {
    'from': from.name,
    'factor': factor,
    'min': min,
    'max': max,
  };
}

class ExerciseTemplate {
  final String exerciseId;
  final String title;

  /// Подходы по уровням. Если уровня пользователя нет — берётся ближайший.
  final Map<PlanLevel, int> setsByLevel;
  final DoseRule? reps;
  final DoseRule? holdSeconds;
  final String? progression;

  const ExerciseTemplate({
    required this.exerciseId,
    required this.title,
    required this.setsByLevel,
    this.reps,
    this.holdSeconds,
    this.progression,
  });

  factory ExerciseTemplate.fromJson(Map<String, dynamic> json, String path) {
    final exerciseId = _require<String>(json, 'exerciseId', path);
    final where = '$path[$exerciseId]';
    final reps = json['reps'];
    final hold = json['holdSeconds'];
    if ((reps == null) == (hold == null)) {
      throw FormatException(
        '$where: нужно ровно одно из полей reps или holdSeconds',
      );
    }
    return ExerciseTemplate(
      exerciseId: exerciseId,
      title: _require<String>(json, 'title', where),
      setsByLevel: _parseSets(json['sets'], '$where.sets'),
      reps: reps == null ? null : DoseRule.fromJson(reps, '$where.reps'),
      holdSeconds: hold == null
          ? null
          : DoseRule.fromJson(hold, '$where.holdSeconds'),
      progression: _optional<String>(json, 'progression', where),
    );
  }

  int setsFor(PlanLevel level) {
    final exact = setsByLevel[level];
    if (exact != null) return exact;
    final nearest = setsByLevel.keys.reduce(
      (a, b) => (a.index - level.index).abs() <= (b.index - level.index).abs()
          ? a
          : b,
    );
    return setsByLevel[nearest]!;
  }

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'title': title,
    'sets': {for (final e in setsByLevel.entries) e.key.name: e.value},
    if (reps case final reps?) 'reps': reps.toJson(),
    if (holdSeconds case final hold?) 'holdSeconds': hold.toJson(),
    'progression': ?progression,
  };

  static Map<PlanLevel, int> _parseSets(Object? json, String where) {
    switch (json) {
      case int sets when sets > 0:
        return {for (final level in PlanLevel.values) level: sets};
      case Map<String, dynamic> byLevel when byLevel.isNotEmpty:
        return {
          for (final MapEntry(:key, :value) in byLevel.entries)
            _parseEnum(PlanLevel.values, key, where): switch (value) {
              int sets when sets > 0 => sets,
              _ => throw FormatException(
                '$where.$key: ожидается положительное число, получено $value',
              ),
            },
        };
      default:
        throw FormatException(
          '$where: ожидается число подходов или {уровень: число}, получено $json',
        );
    }
  }
}

class PlanTemplate {
  final String id;
  final String title;
  final Set<Goal> goals;
  final Set<PlanLevel> levels;
  final Experience experienceFrom;
  final Experience experienceTo;
  final List<int> sessionsPerWeek;
  final List<int> minutesPerSession;
  final int weeks;
  final List<ExerciseTemplate> exercises;
  final String? progression;

  const PlanTemplate({
    required this.id,
    required this.title,
    required this.goals,
    required this.levels,
    required this.experienceFrom,
    required this.experienceTo,
    required this.sessionsPerWeek,
    required this.minutesPerSession,
    required this.weeks,
    required this.exercises,
    this.progression,
  });

  static const allowedSessions = [2, 3, 4, 5];
  static const allowedMinutes = [15, 30, 45, 60];

  factory PlanTemplate.fromJson(Map<String, dynamic> json) {
    final id = _require<String>(json, 'id', 'template');
    final where = 'template[$id]';

    final experience = _require<Map<String, dynamic>>(
      json,
      'experience',
      where,
    );
    final experienceFrom = _parseEnum(
      Experience.values,
      _require<String>(experience, 'from', '$where.experience'),
      '$where.experience.from',
    );
    final experienceTo = _parseEnum(
      Experience.values,
      _require<String>(experience, 'to', '$where.experience'),
      '$where.experience.to',
    );
    if (experienceFrom.index > experienceTo.index) {
      throw FormatException('$where.experience: from позже, чем to');
    }

    final exercisesJson = _require<List<dynamic>>(json, 'exercises', where);
    final exercises = [
      for (final (i, raw) in exercisesJson.indexed)
        switch (raw) {
          Map<String, dynamic> map => ExerciseTemplate.fromJson(
            map,
            '$where.exercises',
          ),
          _ => throw FormatException('$where.exercises[$i]: ожидается объект'),
        },
    ];
    if (exercises.isEmpty) {
      throw FormatException('$where.exercises: список пуст');
    }
    final ids = exercises.map((e) => e.exerciseId).toList();
    if (ids.toSet().length != ids.length) {
      throw FormatException('$where.exercises: exerciseId повторяется');
    }

    final weeks = _require<int>(json, 'weeks', where);
    if (weeks <= 0) throw FormatException('$where.weeks: должно быть > 0');

    return PlanTemplate(
      id: id,
      title: _require<String>(json, 'title', where),
      goals: _parseEnumList(Goal.values, json['goals'], '$where.goals').toSet(),
      levels: _parseEnumList(
        PlanLevel.values,
        json['levels'],
        '$where.levels',
      ).toSet(),
      experienceFrom: experienceFrom,
      experienceTo: experienceTo,
      sessionsPerWeek: _parseOptions(
        json['sessionsPerWeek'],
        allowedSessions,
        '$where.sessionsPerWeek',
      ),
      minutesPerSession: _parseOptions(
        json['minutesPerSession'],
        allowedMinutes,
        '$where.minutesPerSession',
      ),
      weeks: weeks,
      exercises: exercises,
      progression: _optional<String>(json, 'progression', where),
    );
  }

  bool fitsExperience(Experience experience) =>
      experience.index >= experienceFrom.index &&
      experience.index <= experienceTo.index;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'goals': [for (final g in goals) g.name],
    'levels': [for (final l in levels) l.name],
    'experience': {'from': experienceFrom.name, 'to': experienceTo.name},
    'sessionsPerWeek': sessionsPerWeek,
    'minutesPerSession': minutesPerSession,
    'weeks': weeks,
    'exercises': [for (final e in exercises) e.toJson()],
    'progression': ?progression,
  };

  static List<int> _parseOptions(
    Object? json,
    List<int> allowed,
    String where,
  ) {
    final options = switch (json) {
      List<dynamic> list when list.isNotEmpty => [
        for (final v in list)
          if (v is int && allowed.contains(v))
            v
          else
            throw FormatException(
              '$where: допустимы только $allowed, получено $v',
            ),
      ],
      _ => throw FormatException('$where: ожидается непустой список'),
    };
    return options.toSet().toList()..sort();
  }
}

T _require<T>(Map<String, dynamic> json, String key, String where) =>
    switch (json[key]) {
      T value => value,
      final other => throw FormatException(
        '$where.$key: ожидается $T, получено $other',
      ),
    };

T? _optional<T>(Map<String, dynamic> json, String key, String where) =>
    switch (json[key]) {
      T? value => value,
      final other => throw FormatException(
        '$where.$key: ожидается $T, получено $other',
      ),
    };

T _parseEnum<T extends Enum>(List<T> values, String name, String where) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException(
    '$where: неизвестное значение "$name", допустимы ${values.map((v) => v.name).join(', ')}',
  );
}

List<T> _parseEnumList<T extends Enum>(
  List<T> values,
  Object? json,
  String where,
) => switch (json) {
  List<dynamic> list when list.isNotEmpty => [
    for (final item in list)
      if (item is String)
        _parseEnum(values, item, where)
      else
        throw FormatException('$where: ожидается строка, получено $item'),
  ],
  _ => throw FormatException('$where: ожидается непустой список'),
};
