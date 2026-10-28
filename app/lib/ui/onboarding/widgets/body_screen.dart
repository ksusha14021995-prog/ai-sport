import 'package:flutter/material.dart';
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
import '../../core/widgets/surfaces.dart';
import '../onboarding_labels.dart';
import '../view_models/onboarding_view_model.dart';

class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  late final OnboardingViewModel _viewModel;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  bool _isWhyVisible = false;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<OnboardingViewModel>();
    final answers = _viewModel.answers;
    _ageController = TextEditingController(text: answers.age?.toString());
    _heightController =
        TextEditingController(text: answers.heightCm?.toString());
    _weightController =
        TextEditingController(text: answers.weightKg?.round().toString());
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();
    final sex = viewModel.answers.sex;

    return OnboardingScaffold(
      onBack: () => context.popOrGo(Routes.goal),
      step: 4,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Немного о тебе', style: AppText.title),
          const SizedBox(height: 24),
          Text('Пол', style: AppText.sectionLabel),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (index, option) in Sex.values.indexed) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: OptionButton(
                    key: Key('sex-${option.name}'),
                    label: sexLabels[option]!,
                    selected: sex == option,
                    minHeight: 48,
                    fontSize: 15,
                    onTap: () => viewModel.setSex(option),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          LabeledTextField(
            fieldKey: const Key('body-age'),
            label: 'Возраст',
            labelStyle: AppText.sectionLabel,
            controller: _ageController,
            keyboardType: TextInputType.number,
            digitsOnly: true,
            onChanged: (text) => viewModel.setAge(int.tryParse(text)),
            helperText:
                viewModel.answers.age != null && !viewModel.isAgeValid
                    ? 'Укажи возраст от ${OnboardingViewModel.minAge} до '
                        '${OnboardingViewModel.maxAge}'
                    : null,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Text('Рост и вес', style: AppText.sectionLabel)),
              TextButton.icon(
                onPressed: () => setState(() => _isWhyVisible = !_isWhyVisible),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(48, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: appTextStyle(size: 14, weight: FontWeight.w700),
                ),
                icon: const Icon(Icons.help_outline_rounded, size: 16),
                label: const Text('Зачем?'),
              ),
            ],
          ),
          if (_isWhyVisible) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Чтобы точнее подобрать стартовую нагрузку и считать прогресс. '
                'Никому не показываем. Можно пропустить и добавить позже.',
                style: appTextStyle(
                  size: 13,
                  height: 1.45,
                  color: AppColors.onTint,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LabeledTextField(
                  fieldKey: const Key('body-height'),
                  label: 'Рост, см',
                  controller: _heightController,
                  hintText: '165',
                  keyboardType: TextInputType.number,
                  digitsOnly: true,
                  onChanged: (text) =>
                      viewModel.setHeightCm(int.tryParse(text)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LabeledTextField(
                  fieldKey: const Key('body-weight'),
                  label: 'Вес, кг',
                  controller: _weightController,
                  hintText: '60',
                  keyboardType: TextInputType.number,
                  digitsOnly: true,
                  textInputAction: TextInputAction.done,
                  onChanged: (text) =>
                      viewModel.setWeightKg(int.tryParse(text)?.toDouble()),
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: [
        LinkButton(
          label: 'Пропустить рост и вес',
          fontSize: 14,
          onPressed: viewModel.isBodyStepComplete ? _skipMetrics : null,
        ),
        const SizedBox(height: 4),
        PrimaryButton(
          label: 'Дальше',
          onPressed: viewModel.isBodyStepComplete
              ? () => context.push(Routes.calibration)
              : null,
        ),
      ],
    );
  }

  void _skipMetrics() {
    _heightController.clear();
    _weightController.clear();
    _viewModel.skipBodyMetrics();
    context.push(Routes.calibration);
  }
}
