import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/primary_button.dart';
import 'pose_skeleton.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final illustrationSize =
                      (constraints.maxHeight * 0.45).clamp(160.0, 300.0);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Logo(),
                        const SizedBox(height: 12),
                        Center(child: _HeroIllustration(size: illustrationSize)),
                        const SizedBox(height: 12),
                        Text(
                          'Тренер в телефоне, который видит технику',
                          style: AppText.display,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'План под твои цели и ограничения здоровья. Камера '
                          'подсказывает, как исправить движение, прямо во время '
                          'подхода.',
                          style: AppText.lead,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Видео обрабатывается на телефоне и никуда не '
                                'отправляется',
                                style: AppText.hint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Уже есть аккаунт?',
                        style: appTextStyle(
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      LinkButton(
                        label: 'Войти',
                        fontSize: 14,
                        onPressed: () => context.go(Routes.home),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  PrimaryButton(
                    label: 'Начать',
                    onPressed: () => context.push(Routes.signup),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.accessibility_new_rounded,
            size: 22,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'AI-sport',
          style: appTextStyle(
            family: AppFonts.heading,
            size: 18,
            weight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    // Макет рассчитан на круг 300 px — пропорционально масштабируем всё целиком.
    return SizedBox.square(
      dimension: size,
      child: FittedBox(
        child: SizedBox.square(
          dimension: 300,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.tint,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const PoseSkeleton(
                  width: 220,
                  height: 240,
                  highlightLeftKnee: true,
                ),
              ),
              const Positioned(
                left: -6,
                bottom: 54,
                child: _Callout(label: 'Колено внутрь', withDot: true),
              ),
              const Positioned(
                right: -4,
                top: 46,
                child: _Callout(label: 'Техника 8/10'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({required this.label, this.withDot = false});

  final String label;
  final bool withDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A14201A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withDot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.coral,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(label, style: appTextStyle(size: 13, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}
