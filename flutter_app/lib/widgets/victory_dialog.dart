import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game_models.dart';
import '../theme/pop_theme.dart';

class VictoryDialog extends StatelessWidget {
  final int attemptCount;
  final DailyWordInfo? dailyWordInfo;
  final VoidCallback onShare;
  final VoidCallback onClose;

  const VictoryDialog({
    super.key,
    required this.attemptCount,
    this.dailyWordInfo,
    required this.onShare,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: PopTheme.boxDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icona Trofeo Animata
            Icon(Icons.emoji_events_rounded,
                    size: 80, color: PopTheme.yellow)
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .shimmer(delay: 1000.ms, duration: 1500.ms),

            const SizedBox(height: 16),

            // Titolo
            Text(
              'VITTORIA!',
              style: PopTheme.titleStyle.copyWith(fontSize: 36),
            ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),

            const SizedBox(height: 8),

            // Sottotitolo
            Text(
              'Hai indovinato la parola segreta!',
              textAlign: TextAlign.center,
              style: PopTheme.bodyStyle,
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 24),

            // Statistiche Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: PopTheme.boxDecoration(color: PopTheme.cyan),
              child: Column(
                children: [
                  Text(
                    'TENTATIVI',
                    style: PopTheme.bodyStyle.copyWith(fontSize: 14),
                  ),
                  Text(
                    '$attemptCount',
                    style: PopTheme.titleStyle.copyWith(fontSize: 48),
                  ),
                ],
              ),
            ).animate().scale(delay: 700.ms, curve: Curves.elasticOut),

            const SizedBox(height: 32),

            // Bottoni
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onClose,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: PopTheme.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: PopTheme.radius,
                        side: PopTheme.border.top, // Hack to get border
                      ),
                    ).copyWith(
                      side: MaterialStateProperty.all(
                          BorderSide(color: PopTheme.black, width: 3)),
                    ),
                    child: Text('CHIUDI', style: PopTheme.bodyStyle),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onShare();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Risultato copiato negli appunti! 📋'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: PopTheme.yellow,
                      foregroundColor: PopTheme.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: PopTheme.radius,
                        side: BorderSide(color: PopTheme.black, width: 3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.share_rounded),
                        const SizedBox(width: 8),
                        Text('CONDIVIDI', style: PopTheme.bodyStyle),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 900.ms).moveY(begin: 20, end: 0),
          ],
        ),
      ),
    );
  }
}
