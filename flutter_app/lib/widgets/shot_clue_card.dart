import 'package:flutter/material.dart';
import '../theme/pop_theme.dart';

class ShotClueCard extends StatelessWidget {
  final String word;
  final int index;

  const ShotClueCard({
    super.key,
    required this.word,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // Colori alternati per stile Pop Art
    final colors = [
      PopTheme.orange,
      PopTheme.blue,
      PopTheme.green,
      PopTheme.yellow,
      PopTheme.red,
    ];
    
    final color = colors[index % colors.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PopTheme.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: PopTheme.black,
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        word.toUpperCase(),
        style: PopTheme.bodyStyle.copyWith(
          color: PopTheme.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          shadows: [
            Shadow(
              color: PopTheme.black,
              offset: const Offset(1, 1),
              blurRadius: 0,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
