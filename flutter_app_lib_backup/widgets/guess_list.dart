import 'package:flutter/material.dart';
import '../models/game_models.dart';

/// Lista di tentativi
class GuessList extends StatelessWidget {
  final List<GuessResult> guesses;

  const GuessList({super.key, required this.guesses});

  @override
  Widget build(BuildContext context) {
    if (guesses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Inizia a indovinare!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Prova una parola qualsiasi',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Mostra in ordine inverso (più recenti in alto)
    final reversedGuesses = guesses.reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: reversedGuesses.length,
      itemBuilder: (context, index) {
        final guess = reversedGuesses[index];
        final attemptNumber = guesses.length - index;

        return GuessCard(
          guess: guess,
          attemptNumber: attemptNumber,
        );
      },
    );
  }
}

/// Card per singolo tentativo
class GuessCard extends StatelessWidget {
  final GuessResult guess;
  final int attemptNumber;

  const GuessCard({
    super.key,
    required this.guess,
    required this.attemptNumber,
  });

  Color _getBackgroundColor() {
    if (!guess.valid) return Colors.grey.shade200;
    if (guess.correct) return Colors.green.shade100;

    final rank = guess.rank ?? 999999;
    if (rank <= 10) return Colors.red.shade100;
    if (rank <= 100) return Colors.orange.shade100;
    if (rank <= 1000) return Colors.yellow.shade100;
    return Colors.blue.shade50;
  }

  Color _getBorderColor() {
    if (!guess.valid) return Colors.grey;
    if (guess.correct) return Colors.green;

    final rank = guess.rank ?? 999999;
    if (rank <= 10) return Colors.red;
    if (rank <= 100) return Colors.orange;
    if (rank <= 1000) return Colors.yellow.shade700;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: _getBackgroundColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getBorderColor(), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Numero tentativo
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getBorderColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$attemptNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Parola
                Expanded(
                  child: Text(
                    guess.word.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Temperatura
                if (guess.temperature != null)
                  Text(
                    guess.temperature!,
                    style: const TextStyle(fontSize: 18),
                  ),
              ],
            ),

            if (!guess.valid) ...[
              const SizedBox(height: 8),
              Text(
                guess.message ?? 'Parola non valida',
                style: const TextStyle(
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            if (guess.valid && !guess.correct) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.emoji_events,
                      label: 'Rank',
                      value: '#${guess.rank}/${guess.totalWords}',
                    ),
                  ),
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.percent,
                      label: 'Top',
                      value: '${guess.percentile?.toStringAsFixed(2)}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.analytics,
                label: 'Similarità',
                value: guess.similarity?.toStringAsFixed(4) ?? 'N/A',
              ),
            ],

            if (guess.correct) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.celebration, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'PAROLA CORRETTA!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
