import 'package:flutter/material.dart';
import '../theme/pop_theme.dart';

class HalftoneBackground extends StatefulWidget {
  final Widget child;
  final Color dotColor;
  final Color backgroundColor;

  const HalftoneBackground({
    super.key,
    required this.child,
    this.dotColor = const Color(0xFFE0E0E0), // Light grey dots
    this.backgroundColor = const Color(0xFFFAFAFA), // PopTheme.white equivalent
  });

  @override
  State<HalftoneBackground> createState() => _HalftoneBackgroundState();
}

class _HalftoneBackgroundState extends State<HalftoneBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // Slow movement
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Color
        Container(color: widget.backgroundColor),

        // Animated Dots
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _HalftonePainter(
                progress: _controller.value,
                dotColor: widget.dotColor,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class _HalftonePainter extends CustomPainter {
  final double progress;
  final Color dotColor;

  _HalftonePainter({required this.progress, required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const double dotSize = 4.0;
    const double spacing = 20.0;

    // Calculate offset based on animation progress
    // Move diagonally
    final double offsetX = progress * spacing;
    final double offsetY = progress * spacing;

    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(
          Offset(x + offsetX, y + offsetY),
          dotSize / 2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HalftonePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.dotColor != dotColor;
  }
}
