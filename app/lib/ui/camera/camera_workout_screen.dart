import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../domain/technique/squat_state.dart';
import 'view_models/camera_workout_view_model.dart';
import 'widgets/camera_palette.dart';
import 'widgets/camera_unavailable_view.dart';
import 'widgets/debug_overlay.dart';
import 'widgets/skeleton_painter.dart';
import 'widgets/workout_hud.dart';

const _exerciseTitles = {'squat': 'Приседание'};

class CameraWorkoutScreen extends StatefulWidget {
  final String exerciseId;

  const CameraWorkoutScreen({super.key, this.exerciseId = 'squat'});

  @override
  State<CameraWorkoutScreen> createState() => _CameraWorkoutScreenState();
}

class _CameraWorkoutScreenState extends State<CameraWorkoutScreen>
    with WidgetsBindingObserver {
  late final CameraWorkoutViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CameraWorkoutViewModel(exerciseId: widget.exerciseId);
    WidgetsBinding.instance.addObserver(this);
    _viewModel.init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        _viewModel.suspend();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _viewModel.suspend(backgrounded: true);
      case AppLifecycleState.resumed:
        _viewModel.resume();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CameraPalette.background,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return switch (_viewModel.status) {
            CameraStatus.initializing => const Center(
              child: CircularProgressIndicator(color: CameraPalette.accent),
            ),
            CameraStatus.permissionDenied => SafeArea(
              child: CameraUnavailableView.permissionDenied(
                onRetry: _viewModel.init,
              ),
            ),
            CameraStatus.noCamera => const SafeArea(
              child: CameraUnavailableView(
                title: 'Камера не найдена',
                message: 'На этом устройстве нет доступной камеры.',
              ),
            ),
            CameraStatus.failed => SafeArea(
              child: CameraUnavailableView(
                title: 'Не удалось запустить камеру',
                message: _viewModel.errorMessage ?? 'Попробуй ещё раз.',
                onRetry: _viewModel.init,
              ),
            ),
            CameraStatus.ready => _buildWorkout(context),
          };
        },
      ),
    );
  }

  Widget _buildWorkout(BuildContext context) {
    final viewModel = _viewModel;
    return Stack(
      children: [
        const Positioned.fill(
          child: ColoredBox(color: CameraPalette.cameraBackdrop),
        ),
        Positioned.fill(child: _buildPreview(context)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(),
                const SizedBox(height: 20),
                ValueListenableBuilder<SquatState>(
                  valueListenable: viewModel.squat,
                  builder: (context, state, _) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RepCounterCard(
                        reps: state.reps,
                        target: viewModel.targetReps,
                      ),
                      const Spacer(),
                      KneeAngleCard(
                        angle: state.currentAngle,
                        targetAngle: viewModel.analyzer.config.targetDepthAngle,
                      ),
                    ],
                  ),
                ),
                if (viewModel.showDebug) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ValueListenableBuilder<PerfStats>(
                      valueListenable: viewModel.perf,
                      builder: (context, stats, _) => DebugOverlay(
                        stats: stats,
                        resolutionLabel: 'res: ${viewModel.resolution.name}',
                        modelLabel: 'model: ${viewModel.model.name}',
                        phaseLabel: viewModel.squat.value.phase.name,
                        onCycleResolution: viewModel.cycleResolution,
                        onToggleModel: viewModel.toggleModel,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                ValueListenableBuilder<SquatState>(
                  valueListenable: viewModel.squat,
                  builder: (context, state, _) => HintBanner(
                    hint: viewModel.running
                        ? hintFor(
                            state,
                            targetReps: viewModel.targetReps,
                            exerciseSupported: viewModel.isExerciseSupported,
                          )
                        : const Hint(
                            'Пауза',
                            'Нажми «Продолжить», когда будешь готов',
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<SquatState>(
                  valueListenable: viewModel.squat,
                  builder: (context, state, _) => FilledButton(
                    onPressed: _close,
                    style: FilledButton.styleFrom(
                      backgroundColor: CameraPalette.text,
                      foregroundColor: CameraPalette.background,
                      minimumSize: const Size.fromHeight(56),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      state.reps >= viewModel.targetReps
                          ? 'Посмотреть итог подхода'
                          : 'Завершить подход',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    final controller = _viewModel.controller;
    final previewSize = controller?.value.previewSize;
    if (controller == null ||
        !controller.value.isInitialized ||
        previewSize == null) {
      return const SizedBox.shrink();
    }
    // previewSize приходит в ландшафтной ориентации сенсора.
    final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    final width = portrait ? previewSize.height : previewSize.width;
    final height = portrait ? previewSize.width : previewSize.height;
    final minLikelihood = _viewModel.analyzer.config.minLandmarkLikelihood;

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: width,
          height: height,
          child: CameraPreview(
            controller,
            child: ListenableBuilder(
              listenable: Listenable.merge([_viewModel.pose, _viewModel.squat]),
              builder: (context, _) => CustomPaint(
                painter: SkeletonPainter(
                  overlay: _viewModel.pose.value,
                  kneesIn:
                      _viewModel.squat.value.activeError ==
                      TechniqueError.kneesIn,
                  minLikelihood: minLikelihood,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final viewModel = _viewModel;
    return Row(
      children: [
        _RoundButton(
          icon: Icons.close_rounded,
          tooltip: 'Завершить подход',
          onPressed: _close,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.only(left: 16, right: 4),
            decoration: BoxDecoration(
              color: CameraPalette.panel,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _exerciseTitles[widget.exerciseId] ?? widget.exerciseId,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CameraPalette.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: viewModel.showDebug
                      ? 'Скрыть метрики'
                      : 'Показать метрики',
                  onPressed: viewModel.toggleDebug,
                  icon: Icon(
                    Icons.speed_rounded,
                    color: viewModel.showDebug
                        ? CameraPalette.accent
                        : CameraPalette.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (viewModel.canSwitchCamera) ...[
          const SizedBox(width: 10),
          _RoundButton(
            icon: viewModel.lensDirection == CameraLensDirection.front
                ? Icons.camera_rear_outlined
                : Icons.camera_front_outlined,
            tooltip: 'Сменить камеру',
            onPressed: viewModel.switchCamera,
          ),
        ],
        const SizedBox(width: 10),
        _RoundButton(
          icon: viewModel.running
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          tooltip: viewModel.running ? 'Пауза' : 'Продолжить',
          onPressed: viewModel.toggleRunning,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: CameraPalette.panel,
        foregroundColor: CameraPalette.text,
        fixedSize: const Size(48, 48),
      ),
      icon: Icon(icon),
    );
  }
}
