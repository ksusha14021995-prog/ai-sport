import 'package:flutter/material.dart';

import '../../../domain/technique/squat_state.dart';
import 'camera_palette.dart';

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CameraPalette.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class RepCounterCard extends StatelessWidget {
  const RepCounterCard({super.key, required this.reps, required this.target});

  final int reps;
  final int target;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Повторы',
            style: TextStyle(
              color: CameraPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Semantics(
            liveRegion: true,
            label: '$reps из $target повторов',
            child: ExcludeSemantics(
              child: Text.rich(
                TextSpan(
                  text: '$reps',
                  style: const TextStyle(
                    color: CameraPalette.text,
                    fontSize: 34,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    TextSpan(
                      text: ' / $target',
                      style: const TextStyle(
                        color: CameraPalette.muted,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KneeAngleCard extends StatelessWidget {
  const KneeAngleCard({
    super.key,
    required this.angle,
    required this.targetAngle,
  });

  final double? angle;
  final double targetAngle;

  @override
  Widget build(BuildContext context) {
    final angle = this.angle;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Угол в колене',
            style: TextStyle(
              color: CameraPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            angle == null ? '—' : '${angle.round()}°',
            style: const TextStyle(
              color: CameraPalette.text,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'цель — ${targetAngle.round()}°',
            style: const TextStyle(color: CameraPalette.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class Hint {
  const Hint(this.title, this.text, {this.isError = false});
  final String title;
  final String text;
  final bool isError;
}

Hint hintFor(
  SquatState state, {
  required int targetReps,
  required bool exerciseSupported,
}) {
  if (!exerciseSupported) {
    return const Hint(
      'Пока считаем только приседания',
      'Для этого упражнения подсказки по технике появятся позже',
    );
  }
  switch (state.activeError) {
    case TechniqueError.kneesIn:
      return const Hint(
        'Колени уходят внутрь',
        'Разведи их по линии стоп — как будто раздвигаешь пол',
        isError: true,
      );
    case TechniqueError.notDeepEnough:
      return const Hint(
        'Присядь глубже',
        'Опускайся, пока бедро не станет параллельно полу',
        isError: true,
      );
    case null:
      break;
  }
  if (state.reps >= targetReps) {
    return Hint('Подход готов!', '$targetReps из $targetReps. Отдых 60 секунд');
  }
  if (!state.poseVisible) {
    return const Hint(
      'Не вижу тебя целиком',
      'Отойди на 2–3 шага — голова и стопы в кадре',
    );
  }
  if (state.phase == SquatPhase.notReady) {
    return const Hint('Встань прямо', 'Начнём считать, когда увижу тебя стоя');
  }
  return const Hint(
    'Хорошо, так держать',
    'Колени по линии стоп, глубина в норме',
  );
}

class HintBanner extends StatelessWidget {
  const HintBanner({super.key, required this.hint});

  final Hint hint;

  @override
  Widget build(BuildContext context) {
    final foreground = hint.isError ? Colors.white : CameraPalette.darkInk;
    return Semantics(
      liveRegion: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hint.isError ? CameraPalette.error : CameraPalette.text,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hint.isError
                    ? Colors.white.withValues(alpha: 0.18)
                    : CameraPalette.accent,
              ),
              child: Icon(
                hint.isError ? Icons.unfold_less_rounded : Icons.check_rounded,
                color: hint.isError ? Colors.white : CameraPalette.accentInk,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hint.title,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint.text,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      height: 1.4,
                    ),
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
