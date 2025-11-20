import 'package:flutter/material.dart';
import '../models/game_models.dart';

/// Header con informazioni sul gioco
class GameHeader extends StatelessWidget {
  final DailyWordInfo? dailyWordInfo;
  final bool hasWon;
  final int attemptCount;

  const GameHeader({
    super.key,
    this.dailyWordInfo,
    required this.hasWon,
    required this.attemptCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 60, 16, 8), // Top margin for AppBar
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (dailyWordInfo != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GIOCO #${dailyWordInfo!.gameNumber}',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      dailyWordInfo!.date,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history_edu_rounded,
                          size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text(
                        '$attemptCount',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
