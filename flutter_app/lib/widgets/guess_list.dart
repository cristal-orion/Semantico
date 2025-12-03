import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../theme/pop_theme.dart';

/// Lista di tentativi
class GuessList extends StatelessWidget {
  final List<GuessResult> guesses;

  const GuessList({super.key, required this.guesses});

  @override
  Widget build(BuildContext context) {
    if (guesses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(Icons.search_rounded,
                  size: 64, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              'Inizia la ricerca!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scrivi una parola per vedere quanto è vicina.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Ordina per data (dal più recente al più vecchio) per la visualizzazione
    // La lista completa dei tentativi, escludendo solo quelli non validi se vogliamo pulire
    // Ma per ora mostriamo tutto quello che c'è in guesses, reversed.
    final historyGuesses = guesses.reversed.toList();

    return ListView(
      reverse: true, // Ancora la lista al basso
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      children: [
        if (historyGuesses.isNotEmpty) ...[
          ...historyGuesses.map((guess) => GuessCard(
                guess: guess,
                isTop: false,
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Card per singolo tentativo
class GuessCard extends StatelessWidget {
  final GuessResult guess;
  final bool isTop;

  const GuessCard({
    super.key,
    required this.guess,
    this.isTop = false,
  });

  Color _getTemperatureColor() {
    if (!guess.valid) return Colors.grey;
    if (guess.correct) return Colors.green;

    final rank = guess.rank ?? 999999;
    if (rank <= 10) return PopTheme.magenta; // Hot
    if (rank <= 100) return Colors.orangeAccent.shade700; // Warm
    if (rank <= 1000) return PopTheme.yellow; // Tepid
    return PopTheme.cyan; // Cold
  }

  double _getSimilarityPercentage() {
    if (guess.similarity == null) return 0.0;
    // Normalizza similarity (assumendo 0-1 range o simile, ma qui sembra essere 0-100 o raw score)
    // Se similarity è > 1, assumiamo sia percentuale. Se < 1, moltiplichiamo.
    // Dal codice precedente non è chiaro, ma assumiamo sia un valore visualizzabile.
    // Per la barra, usiamo una logica basata sul rank se similarity non è affidabile per UI.
    // Rank 0 = vittoria (100%), Rank 1 = vicinissimo (98%), Rank 10 = 95%
    final rank = guess.rank ?? 100000;
    if (rank == 0) return 1.0; // Solo rank 0 = parola indovinata
    if (rank == 1) return 0.98; // Rank 1 = parola più vicina, non vittoria
    if (rank <= 10) return 0.95;
    if (rank <= 100) return 0.8;
    if (rank <= 1000) return 0.6;
    if (rank <= 5000) return 0.4;
    return 0.2;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTemperatureColor();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: PopTheme.boxDecoration(color: PopTheme.white)
          .copyWith(boxShadow: PopTheme.shadowSmall),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 70, // Increased from 40 to 70
            child: Text(
              guess.valid ? '${guess.rank ?? "???"}' : '',
              style: PopTheme.bodyStyle.copyWith(fontSize: 14),
            ),
          ),

          // Word
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                guess.word.toLowerCase(),
                style: PopTheme.bodyStyle.copyWith(fontSize: 18),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Temperature/Proximity
          SizedBox(
            width: 140, // Increased width
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (guess.correct)
                  Icon(Icons.star_rounded, color: PopTheme.yellow, size: 24)
                else if (!guess.valid)
                  Icon(Icons.help_outline, color: PopTheme.black, size: 18)
                else
                  Expanded(
                    child: Text(
                      // Se rank == 1 ma non correct, mostra messaggio speciale
                      (guess.rank == 1 && !guess.correct)
                          ? '🔥🔥🔥 Vicinissimo!'
                          : (guess.temperature ?? ''),
                      style: PopTheme.bodyStyle.copyWith(
                        fontSize: 14,
                        color: color, // Colora il testo invece del box
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign:
                          TextAlign.right, // Allinea a destra per pulizia
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
