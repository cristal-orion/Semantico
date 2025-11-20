import 'package:flutter/material.dart';
import '../models/game_models.dart';

/// Pannello statistiche con migliori tentativi
class StatsPanel extends StatelessWidget {
  final List<GuessResult> bestGuesses;

  const StatsPanel({super.key, required this.bestGuesses});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Top 5 Tentativi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...bestGuesses.take(5).map((guess) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '${guess.word}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '#${guess.rank}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
