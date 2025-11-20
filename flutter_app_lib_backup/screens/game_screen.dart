import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/guess_input.dart';
import '../widgets/guess_list.dart';
import '../widgets/game_header.dart';
import '../widgets/stats_panel.dart';

/// Schermata principale del gioco
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    // Inizializza il gioco
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Hot & Cold 🧊'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<GameProvider>().refresh();
            },
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          // Loading state
          if (gameProvider.isLoading && gameProvider.guesses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Caricamento gioco...'),
                ],
              ),
            );
          }

          // Error state
          if (!gameProvider.isConnected) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Impossibile connettersi al server',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Assicurati che il backend sia avviato',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => gameProvider.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Riprova'),
                  ),
                ],
              ),
            );
          }

          // Game UI
          return Column(
            children: [
              // Header con info gioco
              GameHeader(
                dailyWordInfo: gameProvider.dailyWordInfo,
                hasWon: gameProvider.hasWon,
                attemptCount: gameProvider.attemptCount,
              ),

              // Stats panel
              if (gameProvider.bestGuesses.isNotEmpty)
                StatsPanel(bestGuesses: gameProvider.bestGuesses),

              // Lista tentativi
              Expanded(
                child: GuessList(guesses: gameProvider.guesses),
              ),

              // Input per nuovi tentativi
              if (!gameProvider.hasWon)
                GuessInput(
                  onSubmit: (word) async {
                    await gameProvider.makeGuess(word);
                  },
                  isLoading: gameProvider.isLoading,
                ),

              // Messaggio vittoria
              if (gameProvider.hasWon)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.green.shade100,
                  child: Column(
                    children: [
                      const Text(
                        '🎉 Congratulazioni! Hai vinto! 🎉',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tentativi: ${gameProvider.attemptCount}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

              // Errore
              if (gameProvider.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade100,
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          gameProvider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Come si gioca'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Indovina la parola segreta del giorno!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Ogni volta che provi una parola, riceverai:',
              ),
              SizedBox(height: 8),
              Text('• Un RANK che indica quanto sei vicino'),
              Text('• Una TEMPERATURA (🔥 = caldo, 🧊 = freddo)'),
              Text('• Una SIMILARITÀ semantica'),
              SizedBox(height: 12),
              Text(
                'Più il rank è basso, più sei vicino alla soluzione!',
              ),
              SizedBox(height: 12),
              Text('🔥🔥🔥 = Top 10 parole più vicine'),
              Text('🔥 = Top 100'),
              Text('🌡️ = Top 500'),
              Text('❄️ = Top 1000'),
              Text('🧊 = Oltre 1000'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
