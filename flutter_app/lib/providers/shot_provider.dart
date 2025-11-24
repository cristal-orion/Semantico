import 'package:flutter/foundation.dart';
import '../models/shot_models.dart';
import '../services/api_service.dart';
import '../services/shot_storage_service.dart';

class ShotProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ShotStorageService _storageService = ShotStorageService();

  ShotGame? _currentGame;
  ShotStats _stats = ShotStats();
  bool _isLoading = false;
  List<String> _guesses = [];
  bool _isGameWon = false;
  String? _targetWord; // Rivelata solo alla fine

  ShotGame? get currentGame => _currentGame;
  ShotStats get stats => _stats;
  bool get isLoading => _isLoading;
  List<String> get guesses => _guesses;
  bool get isGameWon => _isGameWon;
  String? get targetWord => _targetWord;

  ShotProvider() {
    _loadStats();
  }

  Future<void> _loadStats() async {
    _stats = await _storageService.loadStats();
    notifyListeners();
  }

  Future<void> startNewGame() async {
    _isLoading = true;
    _guesses = [];
    _isGameWon = false;
    _targetWord = null;
    notifyListeners();

    try {
      _currentGame = await _apiService.startNewShotGame();
    } catch (e) {
      print('Errore avvio partita Shot: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ShotGuessResult?> makeGuess(String word) async {
    if (_currentGame == null || _isGameWon) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.makeShotGuess(_currentGame!.gameId, word);
      
      if (result != null) {
        _guesses.add(word);
        
        if (result.correct) {
          _isGameWon = true;
          _targetWord = result.targetWord;
          _updateStats(won: true);
        } else {
          // Se vuoi aggiornare statistiche anche per tentativi falliti? No, solo fine partita.
        }
        
        return result;
      }
      return null;
    } catch (e) {
      print('Errore guess Shot: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _updateStats({required bool won}) async {
    int newStreak = won ? _stats.currentStreak + 1 : 0;
    int maxStreak = newStreak > _stats.maxStreak ? newStreak : _stats.maxStreak;
    
    // Calcolo nuova media tentativi (approssimata per semplicità)
    // Media = ((Media * (Giocate-1)) + TentativiAttuali) / Giocate
    // Ma qui è complicato perché aggiorniamo solo alla vittoria.
    // Semplifichiamo: aggiorniamo media solo se vinto
    
    double newAvg = _stats.averageGuesses;
    if (won) {
       double totalGuesses = (_stats.averageGuesses * _stats.gamesWon) + _guesses.length;
       newAvg = totalGuesses / (_stats.gamesWon + 1);
    }

    _stats = _stats.copyWith(
      gamesPlayed: _stats.gamesPlayed + 1, // Conta partita finita
      gamesWon: won ? _stats.gamesWon + 1 : _stats.gamesWon,
      currentStreak: newStreak,
      maxStreak: maxStreak,
      averageGuesses: newAvg,
    );

    await _storageService.saveStats(_stats);
    notifyListeners();
  }
}
