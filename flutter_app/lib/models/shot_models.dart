class ShotGame {
  final String gameId;
  final List<String> clueWords;

  ShotGame({
    required this.gameId,
    required this.clueWords,
  });

  factory ShotGame.fromJson(Map<String, dynamic> json) {
    return ShotGame(
      gameId: json['game_id'],
      clueWords: List<String>.from(json['clue_words']),
    );
  }
}

class ShotGuessResult {
  final bool correct;
  final String? targetWord;
  final String message;

  ShotGuessResult({
    required this.correct,
    this.targetWord,
    required this.message,
  });

  factory ShotGuessResult.fromJson(Map<String, dynamic> json) {
    return ShotGuessResult(
      correct: json['correct'],
      targetWord: json['target_word'],
      message: json['message'],
    );
  }
}

class ShotStats {
  final int gamesPlayed;
  final int gamesWon;
  final int currentStreak;
  final int maxStreak;
  final double averageGuesses;

  ShotStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.averageGuesses = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
      'averageGuesses': averageGuesses,
    };
  }

  factory ShotStats.fromJson(Map<String, dynamic> json) {
    return ShotStats(
      gamesPlayed: json['gamesPlayed'] ?? 0,
      gamesWon: json['gamesWon'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      maxStreak: json['maxStreak'] ?? 0,
      averageGuesses: (json['averageGuesses'] ?? 0.0).toDouble(),
    );
  }

  ShotStats copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? currentStreak,
    int? maxStreak,
    double? averageGuesses,
  }) {
    return ShotStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      averageGuesses: averageGuesses ?? this.averageGuesses,
    );
  }
}
