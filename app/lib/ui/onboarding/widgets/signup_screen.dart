import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/onboarding_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surfaces.dart';
import '../view_models/onboarding_view_model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();

    return OnboardingScaffold(
      onBack: () => context.popOrGo(Routes.welcome),
      step: 1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Создай аккаунт', style: AppText.titleLarge),
          const SizedBox(height: 10),
          Text(
            'Чтобы план и прогресс сохранялись, даже если сменишь телефон.',
            style: appTextStyle(
              size: 15,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          LabeledTextField(
            fieldKey: const Key('signup-email'),
            label: 'Эл. почта',
            controller: _emailController,
            hintText: 'name@mail.ru',
            keyboardType: TextInputType.emailAddress,
            onChanged: viewModel.setEmail,
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            fieldKey: const Key('signup-password'),
            label: 'Пароль',
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            onChanged: viewModel.setPassword,
            textInputAction: TextInputAction.done,
            helperText: 'Минимум 8 символов',
            suffix: IconButton(
              tooltip: _isPasswordVisible ? 'Скрыть пароль' : 'Показать пароль',
              color: AppColors.textSecondary,
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 22,
              ),
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          const SizedBox(height: 24),
          _ConsentCard(
            value: viewModel.consentGiven,
            onChanged: viewModel.setConsent,
          ),
        ],
      ),
      bottom: [
        PrimaryButton(
          label: 'Дальше',
          onPressed: viewModel.canSubmitSignup
              ? () => context.push(Routes.screening)
              : null,
        ),
      ],
    );
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                key: const Key('signup-consent'),
                value: value,
                onChanged: (checked) => onChanged(checked ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text.rich(
                    TextSpan(
                      text: 'Согласна на обработку персональных данных, включая '
                          'данные о здоровье, чтобы подобрать безопасную '
                          'программу. ',
                      children: [
                        TextSpan(
                          text: 'Политика конфиденциальности',
                          style: appTextStyle(
                            size: 13,
                            weight: FontWeight.w600,
                            color: AppColors.primary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                    style: appTextStyle(
                      size: 13,
                      height: 1.45,
                      color: AppColors.textBody,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
