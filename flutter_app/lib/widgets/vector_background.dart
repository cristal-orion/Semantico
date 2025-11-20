import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/pop_theme.dart';

class VectorBackground extends StatefulWidget {
  final Widget child;

  const VectorBackground({
    super.key,
    required this.child,
  });

  @override
  State<VectorBackground> createState() => _VectorBackgroundState();
}

class _VectorBackgroundState extends State<VectorBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Node> _nodes = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize nodes
    for (int i = 0; i < 40; i++) {
      _nodes.add(_Node(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        vx: (_random.nextDouble() - 0.5) * 0.002,
        vy: (_random.nextDouble() - 0.5) * 0.002,
        colorIndex: _random.nextInt(4), // 0: Cyan, 1: Magenta, 2: Yellow, 3: Black/White
        size: 3 + _random.nextDouble() * 5,
      ));
    }
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
        Container(color: PopTheme.white), // Dynamic background
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Update positions
            for (var node in _nodes) {
              node.x += node.vx;
              node.y += node.vy;

              // Bounce off edges
              if (node.x < 0 || node.x > 1) node.vx *= -1;
              if (node.y < 0 || node.y > 1) node.vy *= -1;
            }

            return CustomPaint(
              painter: _VectorPainter(_nodes),
              size: Size.infinite,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _Node {
  double x, y;
  double vx, vy;
  int colorIndex;
  double size;

  _Node({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.colorIndex,
    required this.size,
  });
}

class _VectorPainter extends CustomPainter {
  final List<_Node> nodes;

  _VectorPainter(this.nodes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Dynamic Line Color
    final lineColor = PopTheme.isDarkMode 
        ? Colors.white.withOpacity(0.1) 
        : Colors.black.withOpacity(0.1);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw connections first
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final nodeA = nodes[i];
        final nodeB = nodes[j];

        final dx = (nodeA.x - nodeB.x) * size.width;
        final dy = (nodeA.y - nodeB.y) * size.height;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < 100) {
          linePaint.color = lineColor.withOpacity((1 - dist / 100) * 0.2);
          canvas.drawLine(
            Offset(nodeA.x * size.width, nodeA.y * size.height),
            Offset(nodeB.x * size.width, nodeB.y * size.height),
            linePaint,
          );
        }
      }
    }

    // Draw nodes
    for (var node in nodes) {
      paint.color = _getColor(node.colorIndex);
      canvas.drawCircle(
        Offset(node.x * size.width, node.y * size.height),
        node.size,
        paint,
      );
    }
  }

  Color _getColor(int index) {
    switch (index) {
      case 0: return PopTheme.cyan;
      case 1: return PopTheme.magenta;
      case 2: return PopTheme.yellow;
      case 3: return PopTheme.black; // Will be White in Dark Mode
      default: return PopTheme.black;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
