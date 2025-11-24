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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'STATISTICHE SHOT',
            style: PopTheme.headingStyle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('GIOCATE', stats.gamesPlayed.toString()),
              _buildStatItem('VINTE', stats.gamesWon.toString()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('STREAK', stats.currentStreak.toString()),
              _buildStatItem('MAX', stats.maxStreak.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: PopTheme.headingStyle.copyWith(
            fontSize: 24,
            color: PopTheme.blue,
          ),
        ),
        Text(
          label,
          style: PopTheme.bodyStyle.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
