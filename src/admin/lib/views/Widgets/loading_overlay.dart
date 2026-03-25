import 'package:flutter/material.dart';
import 'package:bouh_admin/theme/colors.dart';

/// Full-screen circular loading overlay using the app's three primary colors.
/// Use [barrierColor: Colors.transparent] or [showBarrier: false] for no dimmed background.
class BouhLoadingOverlay extends StatefulWidget {
  const BouhLoadingOverlay({
    super.key,
    this.barrierColor,
    this.showBarrier = true,
    this.size = 56,
  });

  /// Overrides the dimmed overlay color. Default is semi-transparent black.
  final Color? barrierColor;

  /// When false, no background is drawn (spinner only). Ignored if [barrierColor] is set.
  final bool showBarrier;
  final double size;

  @override
  State<BouhLoadingOverlay> createState() => _BouhLoadingOverlayState();
}

class _BouhLoadingOverlayState extends State<BouhLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _CircularGradientProgressPainter(
                progress: _controller.value,
                colors: const [
                  BColors.primary,
                  BColors.accent,
                  BColors.secondary,
                  BColors.primary,
                ],
                strokeWidth: 3,
              ),
            );
          },
        ),
      ),
    );

    // If no barrier is wanted, don't block touches
    if (!widget.showBarrier && widget.barrierColor == null) {
      return IgnorePointer(
        ignoring: true,
        child: Material(type: MaterialType.transparency, child: child),
      );
    }

    return Material(color: barrierColor, child: child);
  }

  Color get barrierColor {
    if (widget.barrierColor != null) return widget.barrierColor!;
    return widget.showBarrier
        ? Colors.black.withOpacity(0.35)
        : Colors.transparent;
  }
}

class _CircularGradientProgressPainter extends CustomPainter {
  _CircularGradientProgressPainter({
    required this.progress,
    required this.colors,
    this.strokeWidth = 3,
  });

  final double progress;
  final List<Color> colors;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - strokeWidth;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: 2 * 3.14159265359,
      colors: colors,
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const sweepLength = 0.25;
    final startAngle = progress * 2 * 3.14159265359;
    final sweepAngle = sweepLength * 2 * 3.14159265359;
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularGradientProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Inline oval loading indicator using the app's gradient colors.
/// Use inside buttons or small spaces
class BouhOvalLoadingIndicator extends StatefulWidget {
  const BouhOvalLoadingIndicator({
    super.key,
    this.width = 24,
    this.height = 16,
    this.strokeWidth = 2,
  });

  final double width;
  final double height;
  final double strokeWidth;

  @override
  State<BouhOvalLoadingIndicator> createState() =>
      _BouhOvalLoadingIndicatorState();
}

class _BouhOvalLoadingIndicatorState extends State<BouhOvalLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _OvalGradientProgressPainter(
              progress: _controller.value,
              colors: const [
                BColors.primary,
                BColors.accent,
                BColors.secondary,
                BColors.primary,
              ],
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _OvalGradientProgressPainter extends CustomPainter {
  _OvalGradientProgressPainter({
    required this.progress,
    required this.colors,
    this.strokeWidth = 2,
  });

  final double progress;
  final List<Color> colors;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = (size.width / 2) - strokeWidth;
    final h = (size.height / 2) - strokeWidth;
    final rect = Rect.fromCenter(center: center, width: w * 2, height: h * 2);

    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: 2 * 3.14159265359,
      colors: colors,
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const sweepLength = 0.25;
    final startAngle = progress * 2 * 3.14159265359;
    final sweepAngle = sweepLength * 2 * 3.14159265359;
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _OvalGradientProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
