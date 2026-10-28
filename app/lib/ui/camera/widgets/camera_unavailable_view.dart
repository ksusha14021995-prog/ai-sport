import 'package:flutter/material.dart';

import 'camera_palette.dart';

class CameraUnavailableView extends StatelessWidget {
  const CameraUnavailableView({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  const CameraUnavailableView.permissionDenied({super.key, this.onRetry})
    : title = 'Нужен доступ к камере',
      message =
          'Камера нужна, чтобы считать повторы и подсказывать по технике. '
          'Видео не записывается и не покидает телефон.\n\n'
          'Разреши доступ в настройках телефона: '
          'Настройки → Приложения → Ai Sport → Камера — и возвращайся.';

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 56,
              color: CameraPalette.accent,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CameraPalette.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CameraPalette.muted,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: CameraPalette.text,
                  foregroundColor: CameraPalette.background,
                  minimumSize: const Size(220, 56),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Попробовать снова',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
