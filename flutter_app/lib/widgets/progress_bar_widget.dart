import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/pop_theme.dart';

/// Model for player progress
class PlayerProgress {
  final int userId;
  final String username;
  final String? avatarPath;
  final int bestRank;
  final int attempts;
  final bool completed;
  final bool won;
  final bool isFriend;

  PlayerProgress({
    required this.userId,
    required this.username,
    this.avatarPath,
    required this.bestRank,
    required this.attempts,
    required this.completed,
    required this.won,
    this.isFriend = false,
  });

  factory PlayerProgress.fromJson(Map<String, dynamic> json) {
    return PlayerProgress(
      userId: json['user_id'],
      username: json['username'],
      avatarPath: json['avatar_path'],
      bestRank: json['best_rank'],
      attempts: json['attempts'],
      completed: json['completed'],
      won: json['won'],
      isFriend: json['is_friend'] ?? false,
    );
  }

  /// Calculate position on progress bar (0.0 = cold, 1.0 = hot/won)
  double get progressPosition {
    if (won) return 1.0;
    if (bestRank <= 1) return 1.0;
    if (bestRank <= 10) return 0.95;
    if (bestRank <= 50) return 0.85;
    if (bestRank <= 100) return 0.75;
    if (bestRank <= 500) return 0.55;
    if (bestRank <= 1000) return 0.40;
    if (bestRank <= 5000) return 0.25;
    return 0.1; // Very cold
  }
}

/// Widget that shows a horizontal progress bar with player avatars
class ProgressBarWidget extends StatefulWidget {
  final String gameDate;
  final String gameMode;
  final String? authToken;
  final int? currentUserId;
  final int? currentUserBestRank;
  final String? currentUserAvatar;
  final String? currentUserName;
  final bool showFriendsOnly;

  const ProgressBarWidget({
    super.key,
    required this.gameDate,
    this.gameMode = 'daily',
    this.authToken,
    this.currentUserId,
    this.currentUserBestRank,
    this.currentUserAvatar,
    this.currentUserName,
    this.showFriendsOnly = false,
  });

  @override
  State<ProgressBarWidget> createState() => _ProgressBarWidgetState();
}

class _ProgressBarWidgetState extends State<ProgressBarWidget> {
  List<PlayerProgress> _players = [];
  Timer? _pollTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
    // Poll every 5 seconds for updates
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchPlayers();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPlayers() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().getActivePlayers(
        widget.gameDate,
        gameMode: widget.gameMode,
        friendsOnly: widget.showFriendsOnly,
        token: widget.authToken,
      );

      if (response != null && mounted) {
        setState(() {
          _players = response
              .map((json) => PlayerProgress.fromJson(json as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      // Ignore errors for polling
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add current user to display if authenticated and has made guesses
    final allPlayers = [..._players];
    if (widget.currentUserId != null && widget.currentUserBestRank != null) {
      // Check if current user is already in the list
      final existingIndex = allPlayers.indexWhere((p) => p.userId == widget.currentUserId);
      if (existingIndex >= 0) {
        // Update existing user with current best rank
        final existing = allPlayers[existingIndex];
        allPlayers[existingIndex] = PlayerProgress(
          userId: existing.userId,
          username: existing.username,
          avatarPath: existing.avatarPath ?? widget.currentUserAvatar,
          bestRank: widget.currentUserBestRank!,
          attempts: existing.attempts,
          completed: existing.completed,
          won: widget.currentUserBestRank == 1 || existing.won,
          isFriend: existing.isFriend,
        );
      } else {
        // Add current user
        allPlayers.add(PlayerProgress(
          userId: widget.currentUserId!,
          username: widget.currentUserName ?? 'Tu',
          avatarPath: widget.currentUserAvatar,
          bestRank: widget.currentUserBestRank!,
          attempts: 0,
          completed: false,
          won: widget.currentUserBestRank == 1,
          isFriend: false,
        ));
      }
    }

    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background gradient bar (thin, no box)
          Container(
            height: 8,
            margin: const EdgeInsets.only(top: 12, left: 4, right: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400,      // Cold (left)
                  Colors.cyan.shade400,
                  Colors.green.shade400,
                  Colors.yellow.shade500,
                  Colors.orange.shade500,
                  Colors.red.shade500,       // Hot (right)
                ],
              ),
            ),
          ),

          // Goal marker at the end
          Positioned(
            right: 0,
            top: 4,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.flag,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),

          // Player avatars
          ..._buildPlayerAvatars(allPlayers),
        ],
      ),
    );
  }

  List<Widget> _buildPlayerAvatars(List<PlayerProgress> players) {
    final List<Widget> avatars = [];
    final screenWidth = MediaQuery.of(context).size.width - 80; // Minus padding and flag

    // Group players by approximate position to prevent overlap
    final Map<int, List<PlayerProgress>> grouped = {};

    for (final player in players) {
      // Convert position to pixel bucket (every 24 pixels for smaller avatars)
      final pixelPos = (player.progressPosition * screenWidth).round();
      final bucket = (pixelPos / 24).floor();

      grouped.putIfAbsent(bucket, () => []);
      grouped[bucket]!.add(player);
    }

    for (final entry in grouped.entries) {
      final bucket = entry.key;
      final playersInBucket = entry.value;

      for (int i = 0; i < playersInBucket.length && i < 4; i++) { // Max 4 per bucket
        final player = playersInBucket[i];
        final basePos = bucket * 24.0;
        final offset = i * 3.0; // Slight horizontal offset for stacking

        final isCurrentUser = player.userId == widget.currentUserId;

        // If player won, position avatar on the flag (at the end)
        final double leftPosition = player.won
            ? screenWidth + 8 // Position on the flag
            : (basePos + offset).clamp(0, screenWidth - 24);

        avatars.add(
          Positioned(
            left: leftPosition,
            top: 0,
            child: GestureDetector(
              onTap: () => _showPlayerInfo(player),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrentUser
                        ? PopTheme.yellow
                        : player.isFriend
                            ? PopTheme.magenta
                            : Colors.white,
                    width: isCurrentUser ? 2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: player.avatarPath != null
                      ? Image.network(
                          '${ApiService.baseUrl}${player.avatarPath}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(player, isCurrentUser),
                        )
                      : _buildDefaultAvatar(player, isCurrentUser),
                ),
              ),
            ),
          ),
        );
      }
    }

    return avatars;
  }

  Widget _buildDefaultAvatar(PlayerProgress player, [bool isCurrentUser = false]) {
    return Container(
      color: isCurrentUser
          ? PopTheme.yellow
          : player.won
              ? Colors.green.shade300
              : Colors.grey.shade400,
      child: Center(
        child: Text(
          player.username.isNotEmpty ? player.username[0].toUpperCase() : '?',
          style: TextStyle(
            color: PopTheme.black,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  void _showPlayerInfo(PlayerProgress player) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: PopTheme.boxDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: player.isFriend ? PopTheme.magenta : PopTheme.black,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: player.avatarPath != null
                      ? Image.network(
                          '${ApiService.baseUrl}${player.avatarPath}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(player),
                        )
                      : _buildDefaultAvatar(player),
                ),
              ),
              const SizedBox(height: 16),

              // Username
              Text(
                player.username,
                style: PopTheme.headingStyle.copyWith(fontSize: 20),
              ),

              if (player.isFriend)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: PopTheme.magenta,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'AMICO',
                    style: PopTheme.bodyStyle.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat('Tentativi', player.attempts.toString()),
                  _buildStat(
                    'Stato',
                    player.won
                        ? '🏆 VINTO!'
                        : player.completed
                            ? '✗ Fallito'
                            : '⏳ In gioco',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: PopTheme.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  'CHIUDI',
                  style: PopTheme.bodyStyle.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: PopTheme.headingStyle.copyWith(fontSize: 18),
        ),
        Text(
          label,
          style: PopTheme.bodyStyle.copyWith(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
