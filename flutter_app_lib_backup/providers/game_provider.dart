import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game_models.dart';
import '../services/api_service.dart';

/// Provider per gestire lo stato del gioco
class GameProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Stato del gioco
  List<GuessResult> _guesses = [];
  DailyWordInfo? _dailyWordInfo;
  ServerStats? _serverStats;
  bool _isLoading = false;
  bool _isConnected = false;
  String? _errorMessage;
  String? _currentDate;
  bool _hasWon = false;

  // Getters
  List<GuessResult> get guesses => _guesses;
  DailyWordInfo? get dailyWordInfo => _dailyWordInfo;
  ServerStats? get serverStats => _serverStats;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String? get errorMessage => _errorMessage;
  String? get currentDate => _currentDate;
  bool get hasWon => _hasWon;
  
  int get attemptCount => _guesses.length;
  
  // Ottiene migliori tentativi ordinati per rank
  List<GuessResult> get bestGuesses {
    final validGuesses = _guesses.where((g) => g.valid && !g.correct).toList();
    validGuesses.sort((a, b) => (a.rank ?? 999999).compareTo(b.rank ?? 999999));
    return validGuesses;
  }

  /// Inizializza il gioco
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
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
      _dailyWordInfo = await _apiService.getDailyWordInfo();
      _currentDate = _dailyWordInfo?.date;

      // Carica tentativi salvati per oggi
      await _loadSavedGuesses();

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

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'guesses_$_currentDate';
      final saved = prefs.getString(key);

      if (saved != null) {
        final List<dynamic> decoded = json.decode(saved);
        _guesses = decoded.map((e) => GuessResult.fromJson(e)).toList();
        
        // Verifica se ha già vinto
        _hasWon = _guesses.any((g) => g.correct);
      }
    } catch (e) {
      print('Errore caricamento tentativi: $e');
    }
  }

  /// Salva tentativi in locale
  Future<void> _saveGuesses() async {
    if (_currentDate == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'guesses_$_currentDate';
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
      await prefs.remove('guesses_$_currentDate');
    }
    
    notifyListeners();
  }

  /// Ricarica info gioco
  Future<void> refresh() async {
    await initialize();
  }
}
