import 'package:flutter/material.dart';

import '../view_models/camera_workout_view_model.dart';

/// Метрики спайка: главная цель — замерить FPS ML Kit на реальных телефонах.
class DebugOverlay extends StatelessWidget {
  const DebugOverlay({
    super.key,
    required this.stats,
    required this.resolutionLabel,
    required this.modelLabel,
    required this.phaseLabel,
    required this.onCycleResolution,
    required this.onToggleModel,
  });

  final PerfStats stats;
  final String resolutionLabel;
  final String modelLabel;
  final String phaseLabel;
  final VoidCallback onCycleResolution;
  final VoidCallback onToggleModel;

  @override
  Widget build(BuildContext context) {
    final size = stats.imageSize;
    const style = TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontFamily: 'monospace',
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return DefaultTextStyle(
      style: style,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('pose  ${stats.poseFps.toStringAsFixed(1)} fps'),
            Text('cam   ${stats.cameraFps.toStringAsFixed(1)} fps'),
            Text(
              'lat   ${stats.latencyMs.toStringAsFixed(0)} ms (avg ${stats.avgLatencyMs.toStringAsFixed(0)})',
            ),
            Text('drop  ${stats.droppedFrames}'),
            Text(
              'img   ${size == null ? '-' : '${size.width.round()}x${size.height.round()}'}',
            ),
            Text('phase $phaseLabel'),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DebugChip(label: resolutionLabel, onTap: onCycleResolution),
                const SizedBox(width: 6),
                _DebugChip(label: modelLabel, onTap: onToggleModel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugChip extends StatelessWidget {
  const _DebugChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label),
      ),
    );
  }
}
