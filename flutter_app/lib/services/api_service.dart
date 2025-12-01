import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_models.dart';
import '../models/shot_models.dart';

/// Service per comunicare con il backend FastAPI
class ApiService {
  // Modifica questo URL con l'indirizzo del tuo server
  // static const String baseUrl = 'http://localhost:8000';
  // Per testing su dispositivo fisico Android nella stessa rete WiFi:
  static const String baseUrl = 'https://semantico.duckdns.org';
  // static const String baseUrl = 'http://192.168.1.107:8000';

  // Per testing su dispositivo fisico Android, usa:
  // static const String baseUrl = 'http://10.0.2.2:8000';

  // Per testing su rete locale, usa l'IP del tuo PC:
  // static const String baseUrl = 'http://192.168.1.XXX:8000';

  /// Test connessione al server
  Future<bool> testConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Errore connessione: $e');
      return false;
    }
  }

  /// Ottiene statistiche del server
  Future<ServerStats?> getStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ServerStats.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Errore getStats: $e');
      return null;
    }
  }

  /// Ottiene info sulla parola giornaliera
  Future<DailyWordInfo?> getDailyWordInfo({String? date}) async {
    try {
      final uri = date != null
          ? Uri.parse('$baseUrl/daily-word-info?date=$date')
          : Uri.parse('$baseUrl/daily-word-info');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return DailyWordInfo.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Errore getDailyWordInfo: $e');
      return null;
    }
  }

  /// Invia un tentativo
  Future<GuessResult?> makeGuess(String word, {String? date}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/guess'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({
          'word': word,
          if (date != null) 'date': date,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return GuessResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Errore makeGuess: $e');
      return null;
    }
  }

  /// Ottiene un suggerimento casuale
  Future<HintResponse?> getHint({String? date}) async {
    try {
      final uri = date != null
          ? Uri.parse('$baseUrl/hint?date=$date')
          : Uri.parse('$baseUrl/hint');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return HintResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Errore getHint: $e');
      return null;
    }
  }

  /// Ottiene suggerimenti (per debug/testing)
  Future<List<Map<String, dynamic>>?> getHints(String date,
      {int topN = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hint/$date?top_n=$topN'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(data['hints']);
      }
      return null;
    } catch (e) {
      print('❌ Errore getHints: $e');
      return null;
    }
  }
    /// Avvia una nuova partita Shot
  Future<ShotGame?> startNewShotGame() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shot/new-game'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ShotGame.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Errore startNewShotGame: $e');
      return null;
    }
  }

  /// Invia un tentativo Shot
  Future<ShotGuessResult?> makeShotGuess(String gameId, String word) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shot/guess'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({
          'game_id': gameId,
          'guess': word,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ShotGuessResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Errore makeShotGuess: $e');
      return null;
    }
  }

  /// Update player progress for the progress bar
  Future<bool> updateProgress({
    required String token,
    required String gameDate,
    required String gameMode,
    required int bestRank,
    required int attempts,
    bool completed = false,
    bool won = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/game/progress'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'game_date': gameDate,
          'game_mode': gameMode,
          'best_rank': bestRank,
          'attempts': attempts,
          'completed': completed,
          'won': won,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Errore updateProgress: $e');
      return false;
    }
  }

  /// Get active players for the progress bar
  Future<List<dynamic>?> getActivePlayers(
    String gameDate, {
    String gameMode = 'daily',
    bool friendsOnly = false,
    String? token,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/game/players/$gameDate?game_mode=$gameMode&friends_only=$friendsOnly',
      );

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data as List<dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Errore getActivePlayers: $e');
      return null;
    }
  }

  /// Get user game statistics
  Future<Map<String, dynamic>?> getGameStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/game/stats'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      print('❌ Errore getGameStats: $e');
      return null;
    }
  }

  /// Get friends list
  Future<Map<String, dynamic>?> getFriends(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/friends'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      print('❌ Errore getFriends: $e');
      return null;
    }
  }

  /// Send friend request
  Future<bool> sendFriendRequest(String token, int friendId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/friends/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'friend_id': friendId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Errore sendFriendRequest: $e');
      return false;
    }
  }

  /// Accept friend request
  Future<bool> acceptFriendRequest(String token, int friendshipId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/friends/accept/$friendshipId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Errore acceptFriendRequest: $e');
      return false;
    }
  }

  /// Get friends game status for a specific date
  Future<List<dynamic>?> getFriendsGameStatus(
    String token,
    String gameDate, {
    String gameMode = 'daily',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/game/friends/status/$gameDate?game_mode=$gameMode'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      print('❌ Errore getFriendsGameStatus: $e');
      return null;
    }
  }
}
