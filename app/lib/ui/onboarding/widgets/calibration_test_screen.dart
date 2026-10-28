import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/onboarding.dart';
import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/onboarding_scaffold.dart';
import '../../core/widgets/option_button.dart';
import '../../core/widgets/primary_button.dart';
import '../onboarding_labels.dart';
import '../view_models/onboarding_view_model.dart';

enum CalibrationTest { squats, pushups, plank }

/// Калибровка без камеры: пользователь сам вводит повторы и время.
/// Камерную версию (CalibTest.dc.html) подключим, когда будет готов CV-модуль.
class CalibrationTestScreen extends StatefulWidget {
  const CalibrationTestScreen({super.key});

  static const squatDurationSeconds = 60;

  @override
  State<CalibrationTestScreen> createState() => _CalibrationTestScreenState();
}

class _CalibrationTestScreenState extends State<CalibrationTestScreen> {
  final _squatRepsController = TextEditingController();
  final _pushupRepsController = TextEditingController();
  final _plankSecondsController = TextEditingController();

  CalibrationTest _test = CalibrationTest.squats;
  PushupVariant _pushupVariant = PushupVariant.knees;

  Timer? _ticker;
  int _squatSecondsLeft = CalibrationTestScreen.squatDurationSeconds;
  int _plankSeconds = 0;

  bool get _isTicking => _ticker?.isActive ?? false;

  @override
  void dispose() {
    _ticker?.cancel();
    _squatRepsController.dispose();
    _pushupRepsController.dispose();
    _plankSecondsController.dispose();
    super.dispose();
  }

  void _startTicker(void Function() onTick) {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(onTick);
    });
    setState(() {});
  }

  void _stopTicker() {
    _ticker?.cancel();
    setState(() {});
  }

  void _toggleSquatTimer() {
    if (_isTicking) return _stopTicker();
    if (_squatSecondsLeft == 0) {
      _squatSecondsLeft = CalibrationTestScreen.squatDurationSeconds;
    }
    _startTicker(() {
      _squatSecondsLeft--;
      if (_squatSecondsLeft <= 0) {
        _squatSecondsLeft = 0;
        _ticker?.cancel();
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _togglePlankStopwatch() {
    if (_isTicking) return _stopTicker();
    _plankSeconds = 0;
    _plankSecondsController.clear();
    _startTicker(() {
      _plankSeconds++;
      _plankSecondsController.text = '$_plankSeconds';
    });
  }

  int? _parse(TextEditingController controller) =>
      int.tryParse(controller.text);

  bool get _canContinue => switch (_test) {
        CalibrationTest.squats => _parse(_squatRepsController) != null,
        CalibrationTest.pushups => _parse(_pushupRepsController) != null,
        CalibrationTest.plank =>
          _isTicking || (_parse(_plankSecondsController) ?? 0) > 0,
      };

  void _continue() {
    final viewModel = context.read<OnboardingViewModel>();
    switch (_test) {
      case CalibrationTest.squats:
        _ticker?.cancel();
        viewModel.recordSquats(_parse(_squatRepsController)!);
        setState(() => _test = CalibrationTest.pushups);
      case CalibrationTest.pushups:
        viewModel.recordPushups(_pushupVariant, _parse(_pushupRepsController)!);
        setState(() => _test = CalibrationTest.plank);
      case CalibrationTest.plank:
        _stopTicker();
        viewModel.recordPlank(_parse(_plankSecondsController) ?? _plankSeconds);
        context.push(Routes.calibrationDone);
    }
  }

  void _goToPreviousTest() {
    _ticker?.cancel();
    setState(() => _test = CalibrationTest.values[_test.index - 1]);
  }

  @override
  Widget build(BuildContext context) {
    final testNumber = _test.index + 1;

    return PopScope(
      canPop: _test == CalibrationTest.squats,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToPreviousTest();
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 20, 0),
                child: Row(
                  children: [
                    BackIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Выйти из калибровки',
                      color: AppColors.darkText,
                      onPressed: () => context.popOrGo(Routes.calibration),
                    ),
                    Expanded(
                      child: StepProgress(
                        current: testNumber,
                        total: CalibrationTest.values.length,
                        activeColor: AppColors.mint,
                        trackColor: AppColors.darkTrack,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Тест $testNumber из 3',
                      style: appTextStyle(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: _buildTestBody(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: PrimaryButton(
                  tone: ButtonTone.dark,
                  label: switch (_test) {
                    CalibrationTest.squats => 'Дальше: отжимания',
                    CalibrationTest.pushups => 'Дальше: планка',
                    CalibrationTest.plank => 'Всё, отпускаю',
                  },
                  onPressed: _canContinue ? _continue : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestBody() {
    return switch (_test) {
      CalibrationTest.squats => _TestLayout(
          key: const ValueKey(CalibrationTest.squats),
          title: 'Приседания',
          subtitle: 'Максимум за 60 секунд с правильной техникой',
          clockLabel: 'Осталось',
          clockValue: formatSeconds(_squatSecondsLeft),
          clockActionLabel: _isTicking
              ? 'Пауза'
              : (_squatSecondsLeft ==
                      CalibrationTestScreen.squatDurationSeconds
                  ? 'Старт'
                  : (_squatSecondsLeft == 0 ? 'Заново' : 'Продолжить')),
          onClockAction: _toggleSquatTimer,
          inputLabel: 'Сколько чистых повторов получилось?',
          inputKey: const Key('calib-squat-reps'),
          controller: _squatRepsController,
          onInputChanged: () => setState(() {}),
          hint: 'Засчитывай только повторы с правильной техникой',
        ),
      CalibrationTest.pushups => _TestLayout(
          key: const ValueKey(CalibrationTest.pushups),
          title: 'Отжимания',
          subtitle: 'До отказа, в своём темпе',
          header: Row(
            children: [
              for (final (index, variant) in PushupVariant.values.indexed) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: OptionButton(
                    key: Key('pushup-${variant.name}'),
                    label: pushupVariantLabels[variant]!,
                    selected: _pushupVariant == variant,
                    tone: OptionTone.dark,
                    fontWeight: FontWeight.w700,
                    onTap: () => setState(() => _pushupVariant = variant),
                  ),
                ),
              ],
            ],
          ),
          inputLabel: 'Сколько повторов сделал(а)?',
          inputKey: const Key('calib-pushup-reps'),
          controller: _pushupRepsController,
          onInputChanged: () => setState(() {}),
          hint: 'Остановись, когда не сможешь сделать ещё один чисто',
        ),
      CalibrationTest.plank => _TestLayout(
          key: const ValueKey(CalibrationTest.plank),
          title: 'Планка',
          subtitle: 'Держи, пока положение ровное',
          clockLabel: 'Время',
          clockValue: formatSeconds(_plankSeconds),
          clockActionLabel: _isTicking ? 'Стоп' : 'Старт',
          onClockAction: _togglePlankStopwatch,
          inputLabel: 'Сколько секунд продержался(ась)?',
          inputKey: const Key('calib-plank-seconds'),
          controller: _plankSecondsController,
          onInputChanged: () => setState(() {}),
          hint: 'Ровная линия от головы до пяток',
        ),
    };
  }
}

class _TestLayout extends StatelessWidget {
  const _TestLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.inputLabel,
    required this.inputKey,
    required this.controller,
    required this.onInputChanged,
    required this.hint,
    this.header,
    this.clockLabel,
    this.clockValue,
    this.clockActionLabel,
    this.onClockAction,
  });

  final String title;
  final String subtitle;
  final Widget? header;
  final String? clockLabel;
  final String? clockValue;
  final String? clockActionLabel;
  final VoidCallback? onClockAction;
  final String inputLabel;
  final Key inputKey;
  final TextEditingController controller;
  final VoidCallback onInputChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final darkBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.darkBorder),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppText.title.copyWith(color: AppColors.darkText)),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: appTextStyle(size: 14, color: AppColors.darkTextSecondary),
        ),
        if (header != null) ...[const SizedBox(height: 14), header!],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkPanel,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (clockValue != null) ...[
                Text(
                  clockLabel!,
                  style: appTextStyle(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        clockValue!,
                        style: AppText.number(44, color: AppColors.darkText),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: onClockAction,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.mint,
                        side: const BorderSide(color: AppColors.mint),
                        minimumSize: const Size(96, 44),
                        shape: const StadiumBorder(),
                        textStyle: appTextStyle(
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                      ),
                      child: Text(clockActionLabel!),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Text(
                inputLabel,
                style: appTextStyle(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.darkTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                key: inputKey,
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: (_) => onInputChanged(),
                style: AppText.number(22, color: AppColors.darkText),
                cursorColor: AppColors.mint,
                decoration: InputDecoration(
                  fillColor: AppColors.darkBackground,
                  hintText: '0',
                  hintStyle: AppText.number(
                    22,
                    color: AppColors.darkTrack,
                  ),
                  border: darkBorder,
                  enabledBorder: darkBorder,
                  focusedBorder: darkBorder.copyWith(
                    borderSide: const BorderSide(
                      color: AppColors.mint,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: appTextStyle(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
