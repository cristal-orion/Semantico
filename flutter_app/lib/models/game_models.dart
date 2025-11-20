/// Modello per una parola indovinata
class GuessResult {
  final String word;
  final bool valid;
  final bool correct;
  final int? rank;
  final int? totalWords;
  final double? similarity;
  final String? temperature;
  final String? message;

  GuessResult({
    required this.word,
    required this.valid,
    required this.correct,
    this.rank,
    this.totalWords,
    this.similarity,
    this.temperature,
    this.message,
  });

  factory GuessResult.fromJson(Map<String, dynamic> json) {
    return GuessResult(
      word: json['word'] ?? '',
      valid: json['valid'] ?? false,
      correct: json['correct'] ?? false,
      rank: json['rank'],
      totalWords: json['total_words'],
      similarity: json['similarity']?.toDouble(),
      temperature: json['temperature'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'valid': valid,
      'correct': correct,
      'rank': rank,
      'total_words': totalWords,
      'similarity': similarity,
      'temperature': temperature,
      'message': message,
    };
  }

  // Helper per ottenere percentile (top %)
  double? get percentile {
    if (rank == null || totalWords == null) return null;
    return (rank! / totalWords!) * 100;
  }

  // Helper per colore temperatura
  String get temperatureColor {
    if (!valid || correct) return 'correct';
    if (rank == null) return 'cold';

    if (rank! <= 10) return 'very_hot';
    if (rank! <= 100) return 'hot';
    if (rank! <= 1000) return 'warm';
    return 'cold';
  }
}

/// Info sulla parola giornaliera
class DailyWordInfo {
  final String date;
  final int wordLength;
  final int totalWords;
  final int gameNumber;

  DailyWordInfo({
    required this.date,
    required this.wordLength,
    required this.totalWords,
    required this.gameNumber,
  });

  factory DailyWordInfo.fromJson(Map<String, dynamic> json) {
    return DailyWordInfo(
      date: json['date'] ?? '',
      wordLength: json['word_length'] ?? 0,
      totalWords: json['total_words'] ?? 0,
      gameNumber: json['game_number'] ?? 1,
    );
  }
}

/// Statistiche server
class ServerStats {
  final int vocabSize;
  final bool modelLoaded;
  final String todayDate;
  final int todayWordLength;
  final int gameNumber;

  ServerStats({
    required this.vocabSize,
    required this.modelLoaded,
    required this.todayDate,
    required this.todayWordLength,
    required this.gameNumber,
  });

  factory ServerStats.fromJson(Map<String, dynamic> json) {
    return ServerStats(
      vocabSize: json['vocab_size'] ?? 0,
      modelLoaded: json['model_loaded'] ?? false,
      todayDate: json['today_date'] ?? '',
      todayWordLength: json['today_word_length'] ?? 0,
      gameNumber: json['game_number'] ?? 1,
    );
  }
}

/// Suggerimento (hint)
class HintResponse {
  final String hintWord;
  final String message;

  HintResponse({
    required this.hintWord,
    required this.message,
  });

  factory HintResponse.fromJson(Map<String, dynamic> json) {
    return HintResponse(
      hintWord: json['hint_word'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
