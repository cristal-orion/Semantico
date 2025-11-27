import 'package:flutter/material.dart';
import '../models/shot_models.dart';
import '../theme/pop_theme.dart';

class ShotStatsWidget extends StatelessWidget {
  final ShotStats stats;

  const ShotStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PopTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PopTheme.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: PopTheme.black,
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Center(
            child: Text(
              'STATISTICHE SHOT',
              style: PopTheme.headingStyle.copyWith(fontSize: 18),
            ),
          ),
          const SizedBox(height: 16),

          // Performance Overview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('🎯\nPARTITE', stats.totalGames.toString(), PopTheme.blue),
              _buildStatItem('✅\nVINTE', stats.gamesWon.toString(), PopTheme.green),
              _buildStatItem('⏭️\nSALTATE', stats.gamesSkipped.toString(), PopTheme.magenta),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.black26, thickness: 1),
          const SizedBox(height: 12),

          // Win Rate (se ci sono partite)
          if (stats.totalGames > 0) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: PopTheme.yellow.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PopTheme.black, width: 1),
                ),
                child: Text(
                  'TASSO VITTORIA: ${stats.winRate.toStringAsFixed(1)}%',
                  style: PopTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Tentativi Stats (solo se ha vinto almeno una volta)
          if (stats.gamesWon > 0) ...[
            Text(
              'PERFORMANCE TENTATIVI:',
              style: PopTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('📊\nMEDIA', stats.averageGuesses.toStringAsFixed(1), PopTheme.blue),
                _buildStatItem('⭐\nMIGLIORE', stats.bestPerformance.toString(), PopTheme.green),
                _buildStatItem('📈\nPEGGIORE', stats.worstPerformance.toString(), PopTheme.magenta),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.black26, thickness: 1),
            const SizedBox(height: 12),
          ],

          // Fast Win Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('🔥\nSTREAK VELOCE', stats.fastWinStreak.toString(), Colors.orange),
              _buildStatItem('🏆\nRECORD STREAK', stats.maxFastWinStreak.toString(), Colors.deepOrange),
            ],
          ),

          const SizedBox(height: 12),
          Center(
            child: Text(
              'Streak veloce = vittorie con ≤5 tentativi',
              style: PopTheme.bodyStyle.copyWith(
                fontSize: 10,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: PopTheme.headingStyle.copyWith(
            fontSize: 22,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: PopTheme.bodyStyle.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
