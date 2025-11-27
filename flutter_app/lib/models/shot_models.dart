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
  final int totalGames;        // Totale partite (vinte + skippate)
  final int gamesWon;          // Partite vinte
  final int gamesSkipped;      // Partite skippate/arrese
  final double averageGuesses; // Media tentativi per vittoria
  final int bestPerformance;   // Minimo tentativi per vincere (0 = nessuna vittoria)
  final int worstPerformance;  // Massimo tentativi per vincere
  final int fastWinStreak;     // Streak corrente di vittorie con ≤5 tentativi
  final int maxFastWinStreak;  // Miglior streak di vittorie veloci

  ShotStats({
    this.totalGames = 0,
    this.gamesWon = 0,
    this.gamesSkipped = 0,
    this.averageGuesses = 0.0,
    this.bestPerformance = 0,
    this.worstPerformance = 0,
    this.fastWinStreak = 0,
    this.maxFastWinStreak = 0,
  });

  // Percentuale vittorie
  double get winRate => totalGames > 0 ? (gamesWon / totalGames * 100) : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'totalGames': totalGames,
      'gamesWon': gamesWon,
      'gamesSkipped': gamesSkipped,
      'averageGuesses': averageGuesses,
      'bestPerformance': bestPerformance,
      'worstPerformance': worstPerformance,
      'fastWinStreak': fastWinStreak,
      'maxFastWinStreak': maxFastWinStreak,
    };
  }

  factory ShotStats.fromJson(Map<String, dynamic> json) {
    return ShotStats(
      totalGames: json['totalGames'] ?? 0,
      gamesWon: json['gamesWon'] ?? 0,
      gamesSkipped: json['gamesSkipped'] ?? 0,
      averageGuesses: (json['averageGuesses'] ?? 0.0).toDouble(),
      bestPerformance: json['bestPerformance'] ?? 0,
      worstPerformance: json['worstPerformance'] ?? 0,
      fastWinStreak: json['fastWinStreak'] ?? 0,
      maxFastWinStreak: json['maxFastWinStreak'] ?? 0,
    );
  }

  ShotStats copyWith({
    int? totalGames,
    int? gamesWon,
    int? gamesSkipped,
    double? averageGuesses,
    int? bestPerformance,
    int? worstPerformance,
    int? fastWinStreak,
    int? maxFastWinStreak,
  }) {
    return ShotStats(
      totalGames: totalGames ?? this.totalGames,
      gamesWon: gamesWon ?? this.gamesWon,
      gamesSkipped: gamesSkipped ?? this.gamesSkipped,
      averageGuesses: averageGuesses ?? this.averageGuesses,
      bestPerformance: bestPerformance ?? this.bestPerformance,
      worstPerformance: worstPerformance ?? this.worstPerformance,
      fastWinStreak: fastWinStreak ?? this.fastWinStreak,
      maxFastWinStreak: maxFastWinStreak ?? this.maxFastWinStreak,
    );
  }
}
