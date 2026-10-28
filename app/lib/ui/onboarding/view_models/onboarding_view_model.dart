import 'package:flutter/foundation.dart';

import '../../../domain/models/onboarding.dart';
import '../../../domain/models/training_plan.dart';

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({required this._planBuilder});

  static const minAge = 18;
  static const maxAge = 100;
  static const minPasswordLength = 8;

  final PlanBuilder _planBuilder;

  OnboardingAnswers _answers = OnboardingAnswers();
  OnboardingAnswers get answers => _answers;

  // --- Регистрация (без реальной авторизации) ---

  String _email = '';
  String _password = '';
  bool _consentGiven = false;

  bool get consentGiven => _consentGiven;
  bool get isEmailValid => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email);
  bool get isPasswordValid => _password.length >= minPasswordLength;
  bool get canSubmitSignup => isEmailValid && isPasswordValid && _consentGiven;

  void setEmail(String value) {
    _email = value.trim();
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  void setConsent(bool value) {
    _consentGiven = value;
    notifyListeners();
  }

  // --- Скрининг ---

  int get screeningAnsweredCount =>
      _answers.screening.answers.where((answer) => answer != null).length;
  bool get isScreeningComplete => _answers.screening.isComplete;
  bool get isScreeningPassed => _answers.screening.isPassed;

  bool? screeningAnswer(int index) => _answers.screening.answers[index];

  void answerScreening(int index, bool value) {
    _answers = _answers.copyWith(
      screening: _answers.screening.answer(index, value),
    );
    notifyListeners();
  }

  // --- Цель и возможности ---

  bool get isGoalStepComplete =>
      _answers.goals.isNotEmpty &&
      _answers.experience != null &&
      _answers.daysPerWeek != null &&
      _answers.minutesPerSession != null;

  void toggleGoal(Goal goal) {
    final goals = {..._answers.goals};
    if (!goals.remove(goal)) goals.add(goal);
    _answers = _answers.copyWith(goals: goals);
    notifyListeners();
  }

  void setExperience(Experience value) {
    _answers = _answers.copyWith(experience: value);
    notifyListeners();
  }

  void setDaysPerWeek(int value) {
    _answers = _answers.copyWith(daysPerWeek: value);
    notifyListeners();
  }

  void setMinutesPerSession(int value) {
    _answers = _answers.copyWith(minutesPerSession: value);
    notifyListeners();
  }

  // --- Данные тела ---

  bool get isAgeValid {
    final age = _answers.age;
    return age != null && age >= minAge && age <= maxAge;
  }

  bool get isBodyStepComplete => _answers.sex != null && isAgeValid;

  void setSex(Sex value) {
    _answers = _answers.copyWith(sex: value);
    notifyListeners();
  }

  void setAge(int? value) {
    _answers = _rebuild(age: value);
    notifyListeners();
  }

  void setHeightCm(int? value) {
    _answers = _rebuild(heightCm: value);
    notifyListeners();
  }

  void setWeightKg(double? value) {
    _answers = _rebuild(weightKg: value);
    notifyListeners();
  }

  void skipBodyMetrics() {
    _answers = _rebuild(heightCm: null, weightKg: null);
    notifyListeners();
  }

  // --- Калибровка ---

  int? _squatReps;
  int? _pushupReps;
  PushupVariant _pushupVariant = PushupVariant.knees;
  int? _plankSeconds;
  int? _perceivedDifficulty;

  int? get squatReps => _squatReps;
  int? get pushupReps => _pushupReps;
  PushupVariant get pushupVariant => _pushupVariant;
  int? get plankSeconds => _plankSeconds;
  int? get perceivedDifficulty => _perceivedDifficulty;

  void recordSquats(int reps) {
    _squatReps = reps;
    notifyListeners();
  }

  void recordPushups(PushupVariant variant, int reps) {
    _pushupVariant = variant;
    _pushupReps = reps;
    notifyListeners();
  }

  void recordPlank(int seconds) {
    _plankSeconds = seconds;
    notifyListeners();
  }

  void setPerceivedDifficulty(int value) {
    _perceivedDifficulty = value;
    _answers = _answers.copyWith(
      calibration: CalibrationResult(
        squatReps: _squatReps ?? 0,
        // Ошибки техники пока не считаем: ручной ввод без камеры.
        squatErrors: 0,
        pushupReps: _pushupReps ?? 0,
        pushupVariant: _pushupVariant,
        plankSeconds: _plankSeconds ?? 0,
        plankErrors: 0,
        perceivedDifficulty: value,
      ),
    );
    notifyListeners();
  }

  // --- План ---

  TrainingPlan? _plan;
  bool _isBuildingPlan = false;
  Object? _planError;

  TrainingPlan? get plan => _plan;
  bool get isBuildingPlan => _isBuildingPlan;
  Object? get planError => _planError;

  Future<void> buildPlan() async {
    if (_isBuildingPlan) return;
    _isBuildingPlan = true;
    _planError = null;
    notifyListeners();
    try {
      _plan = await _planBuilder.build(_answers);
    } on Object catch (error) {
      _planError = error;
    } finally {
      _isBuildingPlan = false;
      notifyListeners();
    }
  }

  static const Object _keep = Object();

  /// [OnboardingAnswers.copyWith] не умеет сбрасывать поля в null.
  OnboardingAnswers _rebuild({
    Object? age = _keep,
    Object? heightCm = _keep,
    Object? weightKg = _keep,
  }) {
    final current = _answers;
    return OnboardingAnswers(
      screening: current.screening,
      goals: current.goals,
      experience: current.experience,
      daysPerWeek: current.daysPerWeek,
      minutesPerSession: current.minutesPerSession,
      sex: current.sex,
      age: identical(age, _keep) ? current.age : age as int?,
      heightCm:
          identical(heightCm, _keep) ? current.heightCm : heightCm as int?,
      weightKg:
          identical(weightKg, _keep) ? current.weightKg : weightKg as double?,
      calibration: current.calibration,
    );
  }
}
