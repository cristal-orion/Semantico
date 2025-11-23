import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_models.dart';

/// Service per comunicare con il backend FastAPI
class ApiService {
  // Modifica questo URL con l'indirizzo del tuo server
  // static const String baseUrl = 'http://localhost:8000';
  // Per testing su dispositivo fisico Android nella stessa rete WiFi:
  static const String baseUrl = 'https://semantico.duckdns.org';

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
}
