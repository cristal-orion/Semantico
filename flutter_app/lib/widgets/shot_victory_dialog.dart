import 'package:flutter/material.dart';
import '../theme/pop_theme.dart';

class ShotVictoryDialog extends StatelessWidget {
  final String targetWord;
  final VoidCallback onNewGame;

  const ShotVictoryDialog({
    super.key,
    required this.targetWord,
    required this.onNewGame,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PopTheme.yellow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PopTheme.black, width: 3),
          boxShadow: [
            BoxShadow(
              color: PopTheme.black,
              offset: const Offset(6, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VITTORIA!',
              style: PopTheme.headingStyle.copyWith(
                fontSize: 32,
                color: PopTheme.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'La parola era:',
              style: PopTheme.bodyStyle,
            ),
            const SizedBox(height: 8),
            Text(
              targetWord.toUpperCase(),
              style: PopTheme.headingStyle.copyWith(
                fontSize: 28,
                color: PopTheme.blue,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onNewGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PopTheme.green,
                foregroundColor: PopTheme.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: PopTheme.black, width: 2),
                ),
                elevation: 0,
              ),
              child: Text(
                'NUOVA PARTITA',
                style: PopTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: PopTheme.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
