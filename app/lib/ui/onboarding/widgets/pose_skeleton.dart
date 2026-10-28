import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Скелет в приседе из макета Main.dc.html (viewBox 220×240).
class PoseSkeleton extends StatelessWidget {
  const PoseSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.highlightLeftKnee = false,
  });

  final double width;
  final double height;
  final bool highlightLeftKnee;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Схема скелета человека в приседе',
      child: CustomPaint(
        size: Size(width, height),
        painter: _SkeletonPainter(highlightLeftKnee: highlightLeftKnee),
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter({required this.highlightLeftKnee});

  final bool highlightLeftKnee;

  static const _bones = <(Offset, Offset)>[
    (Offset(110, 62), Offset(104, 118)),
    (Offset(80, 74), Offset(140, 74)),
    (Offset(80, 74), Offset(64, 112)),
    (Offset(64, 112), Offset(46, 96)),
    (Offset(140, 74), Offset(158, 112)),
    (Offset(158, 112), Offset(176, 96)),
    (Offset(104, 118), Offset(82, 122)),
    (Offset(104, 118), Offset(128, 122)),
    (Offset(82, 122), Offset(62, 168)),
    (Offset(128, 122), Offset(150, 168)),
    (Offset(62, 168), Offset(72, 216)),
    (Offset(150, 168), Offset(140, 216)),
  ];

  static const _joints = <Offset>[
    Offset(80, 74),
    Offset(140, 74),
    Offset(64, 112),
    Offset(158, 112),
    Offset(82, 122),
    Offset(128, 122),
    Offset(72, 216),
    Offset(140, 216),
    Offset(150, 168),
  ];

  static const _leftKnee = Offset(62, 168);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 220, size.height / 240);

    final bone = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (final (start, end) in _bones) {
      canvas.drawLine(start, end, bone);
    }

    canvas.drawCircle(
      const Offset(110, 40),
      18,
      Paint()..color = AppColors.primary,
    );

    final jointFill = Paint()..color = Colors.white;
    final jointStroke = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    for (final joint in _joints) {
      canvas.drawCircle(joint, 7, jointFill);
      canvas.drawCircle(joint, 7, jointStroke);
    }

    final kneeRadius = highlightLeftKnee ? 9.0 : 7.0;
    canvas.drawCircle(
      _leftKnee,
      kneeRadius,
      Paint()
        ..color = highlightLeftKnee ? AppColors.coralContainer : Colors.white,
    );
    canvas.drawCircle(
      _leftKnee,
      kneeRadius,
      jointStroke
        ..color = highlightLeftKnee ? AppColors.coral : AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_SkeletonPainter oldDelegate) =>
      oldDelegate.highlightLeftKnee != highlightLeftKnee;
}
