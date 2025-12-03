import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game_models.dart';
import '../services/api_service.dart';

/// Provider per gestire lo stato del gioco
class GameProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Auth token for progress updates (set from outside)
  String? authToken;
  int? userId; // User ID for per-user guess storage

  // Stato del gioco
  List<GuessResult> _guesses = [];
  DailyWordInfo? _dailyWordInfo;
  ServerStats? _serverStats;
  bool _isLoading = false;
  bool _isConnected = false;
  String? _errorMessage;
  String? _currentDate;
  bool _hasWon = false;
  bool _isDarkMode = false;

  // Getters
  List<GuessResult> get guesses => _guesses;
  DailyWordInfo? get dailyWordInfo => _dailyWordInfo;
  ServerStats? get serverStats => _serverStats;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String? get errorMessage => _errorMessage;
  String? get currentDate => _currentDate;
  bool get hasWon => _hasWon;
  bool get isDarkMode => _isDarkMode;

  int get attemptCount => _guesses.length;

  // Ottiene migliori tentativi ordinati per rank
  List<GuessResult> get bestGuesses {
    final validGuesses = _guesses.where((g) => g.valid && !g.correct).toList();
    validGuesses.sort((a, b) => (a.rank ?? 999999).compareTo(b.rank ?? 999999));
    return validGuesses;
  }

  /// Pulisce lo stato corrente (memoria)
  void clearCurrentState() {
    _guesses = [];
    _dailyWordInfo = null;
    _currentDate = null;
    _hasWon = false;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Inizializza il gioco
  Future<void> initialize({String? date}) async {
    clearCurrentState();
    _isLoading = true;
    notifyListeners();

    try {
      // Test connessione
      _isConnected = await _apiService.testConnection();

      if (!_isConnected) {
        _errorMessage = 'Impossibile connettersi al server';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Carica stats
      _serverStats = await _apiService.getStats();

      // Carica info parola giornaliera
      _dailyWordInfo = await _apiService.getDailyWordInfo(date: date);
      _currentDate = _dailyWordInfo?.date;

      // Carica tentativi salvati per oggi
      await _loadSavedGuesses();

      // Carica preferenza tema
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Errore durante inizializzazione: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carica tentativi salvati in locale
  Future<void> _loadSavedGuesses() async {
    if (_currentDate == null) return;

    // Reset stato prima di caricare
    _guesses = [];
    _hasWon = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      // Include userId in key for per-user storage (fallback to 'guest' if not logged in)
      final userKey = userId != null ? 'user_${userId}_' : 'guest_';
      final key = '${userKey}guesses_$_currentDate';
      final saved = prefs.getString(key);

      if (saved != null) {
        final List<dynamic> decoded = json.decode(saved);
        _guesses = decoded.map((e) => GuessResult.fromJson(e)).toList();

        // Verifica se ha già vinto (solo se ci sono tentativi)
        if (_guesses.isNotEmpty) {
          _hasWon = _guesses.any((g) => g.correct);
        }
      }
    } catch (e) {
      print('Errore caricamento tentativi: $e');
      _guesses = [];
      _hasWon = false;
    }
  }

  /// Salva tentativi in locale
  Future<void> _saveGuesses() async {
    if (_currentDate == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      // Include userId in key for per-user storage (fallback to 'guest' if not logged in)
      final userKey = userId != null ? 'user_${userId}_' : 'guest_';
      final key = '${userKey}guesses_$_currentDate';
      final encoded = json.encode(_guesses.map((e) => e.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (e) {
      print('Errore salvataggio tentativi: $e');
    }
  }

  /// Invia un tentativo
  Future<bool> makeGuess(String word) async {
    if (_hasWon) return false;

    // Verifica se già provata
    if (_guesses.any((g) => g.word.toLowerCase() == word.toLowerCase())) {
      _errorMessage = 'Parola già provata!';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.makeGuess(word, date: _currentDate);

      if (result == null) {
        _errorMessage = 'Errore durante il tentativo';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _guesses.add(result);

      if (result.correct) {
        _hasWon = true;
      }

      await _saveGuesses();

      // Update progress on server if authenticated
      await _updateProgress();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Errore: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset gioco (per testing o nuovo giorno)
  Future<void> resetGame() async {
    _guesses.clear();
    _hasWon = false;
    _errorMessage = null;

    if (_currentDate != null) {
      final prefs = await SharedPreferences.getInstance();
      final userKey = userId != null ? 'user_${userId}_' : 'guest_';
      await prefs.remove('${userKey}guesses_$_currentDate');
    }

    notifyListeners();
  }

  /// Ricarica info gioco
  Future<void> refresh() async {
    await initialize();
  }

  /// Ottiene un suggerimento (graduale se autenticato)
  Future<String?> getHint() async {
    if (_hasWon) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final hint =
          await _apiService.getHint(date: _currentDate, token: authToken);

      _isLoading = false;
      notifyListeners();

      if (hint != null) {
        return hint.hintWord;
      }
      return null;
    } catch (e) {
      _errorMessage = 'Errore durante il suggerimento: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Cambia tema
  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  /// Update progress on server for progress bar
  Future<void> _updateProgress() async {
    if (authToken == null || _currentDate == null) return;

    // Calculate best rank
    int bestRank = 999999;
    for (final guess in _guesses) {
      if (guess.valid && guess.rank != null && guess.rank! < bestRank) {
        bestRank = guess.rank!;
      }
    }

    try {
      await _apiService.updateProgress(
        token: authToken!,
        gameDate: _currentDate!,
        gameMode: 'daily',
        bestRank: bestRank,
        attempts: _guesses.length,
        completed: _hasWon,
        won: _hasWon,
      );
    } catch (e) {
      // Ignore errors for progress updates
      print('Error updating progress: $e');
    }
  }
}
