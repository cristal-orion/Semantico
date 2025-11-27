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

  // Skip/Arrenditi alla partita corrente
  Future<void> skipGame() async {
    if (_currentGame == null) return;

    _stats = _stats.copyWith(
      totalGames: _stats.totalGames + 1,
      gamesSkipped: _stats.gamesSkipped + 1,
      fastWinStreak: 0, // Reset streak quando skippiamo
    );

    await _storageService.saveStats(_stats);

    // Inizia nuova partita
    await startNewGame();
  }

  Future<void> _updateStats({required bool won}) async {
    if (!won) return; // Non aggiorniamo statistiche se non ha vinto

    final numGuesses = _guesses.length;

    // Calcola nuova media tentativi
    double totalGuesses = (_stats.averageGuesses * _stats.gamesWon) + numGuesses;
    double newAvg = totalGuesses / (_stats.gamesWon + 1);

    // Aggiorna best/worst performance
    int newBest = _stats.bestPerformance == 0
        ? numGuesses
        : (numGuesses < _stats.bestPerformance ? numGuesses : _stats.bestPerformance);
    int newWorst = numGuesses > _stats.worstPerformance ? numGuesses : _stats.worstPerformance;

    // Calcola fast win streak (vittorie con ≤5 tentativi)
    int newFastStreak = numGuesses <= 5 ? _stats.fastWinStreak + 1 : 0;
    int newMaxFastStreak = newFastStreak > _stats.maxFastWinStreak
        ? newFastStreak
        : _stats.maxFastWinStreak;

    _stats = _stats.copyWith(
      totalGames: _stats.totalGames + 1,
      gamesWon: _stats.gamesWon + 1,
      averageGuesses: newAvg,
      bestPerformance: newBest,
      worstPerformance: newWorst,
      fastWinStreak: newFastStreak,
      maxFastWinStreak: newMaxFastStreak,
    );

    await _storageService.saveStats(_stats);
    notifyListeners();
  }
}
