import '../../domain/models/onboarding.dart';
import '../../domain/models/training_plan.dart';

/// Дословно из макета Screening.dc.html (на «вы» — так в схеме онбординга).
const screeningQuestions = <String>[
  'Говорил ли врач, что у вас проблемы с сердцем или повышенное давление?',
  'Бывает ли боль в груди — в покое, в быту или при нагрузке?',
  'Теряли ли вы сознание или равновесие из-за головокружения за последние 12 месяцев?',
  'Есть ли у вас другое хроническое заболевание?',
  'Принимаете ли вы лекарства на постоянной основе?',
  'Есть ли проблемы с суставами, костями или мышцами, которые может усилить нагрузка?',
  'Рекомендовал ли врач заниматься только под медицинским контролем?',
  'Вам меньше 18 лет?',
  'Вы беременны?',
];

const goalLabels = <Goal, String>{
  Goal.loseWeight: 'Снизить вес',
  Goal.gainMass: 'Набрать массу',
  Goal.getStronger: 'Стать сильнее',
  Goal.endurance: 'Повысить выносливость',
  Goal.tone: 'Общий тонус',
};

const experienceLabels = <Experience, String>{
  Experience.none: 'Не тренируюсь',
  Experience.under6Months: 'До 6 месяцев',
  Experience.from6To24Months: '6–24 месяца',
  Experience.over2Years: 'Больше 2 лет',
};

const daysPerWeekOptions = <int, String>{2: '2', 3: '3', 4: '4', 5: '5+'};

const minutesPerSessionOptions = <int, String>{
  15: '15',
  30: '30',
  45: '45',
  60: '60',
};

const sexLabels = <Sex, String>{Sex.female: 'Женский', Sex.male: 'Мужской'};

const pushupVariantLabels = <PushupVariant, String>{
  PushupVariant.floor: 'От пола',
  PushupVariant.knees: 'С колен',
};

const planLevelLabels = <PlanLevel, String>{
  PlanLevel.beginner: 'Начальный',
  PlanLevel.intermediate: 'Средний',
  PlanLevel.advanced: 'Продвинутый',
};

String formatSeconds(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
