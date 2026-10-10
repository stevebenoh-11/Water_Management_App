import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Large circular progress ring with content in the middle.
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 260,
    this.color = AppColors.blue,
  });

  /// 0.0 – 1.0 (how much of the fill is done).
  final double progress;
  final Widget child;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress.clamp(0.0, 1.0), color),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    // Soft water fill rising inside the ring.
    final inner = rect.deflate(stroke + 6);
    canvas.save();
    canvas.clipPath(Path()..addOval(inner));
    final waterTop = inner.bottom - inner.height * progress;
    canvas.drawRect(
      Rect.fromLTRB(inner.left, waterTop, inner.right, inner.bottom),
      Paint()..color = AppColors.aqua.withValues(alpha: 0.18),
    );
    canvas.restore();

    canvas.drawArc(
      arcRect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color.withValues(alpha: 0.15),
    );
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [AppColors.aqua, AppColors.blue, AppColors.teal],
        ).createShader(arcRect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
