import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/guess_input.dart';
import '../widgets/guess_list.dart';
import '../widgets/guess_input.dart';
import '../widgets/guess_list.dart';
import '../widgets/victory_dialog.dart';
import '../theme/pop_theme.dart';
import 'package:flutter/services.dart'; // For Clipboard


/// Schermata principale del gioco
class GameScreen extends StatefulWidget {
  final String? date;

  const GameScreen({super.key, this.date});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _victoryShown = false;

  @override
  void dispose() {
    // Pulisce lo stato quando si esce dalla schermata
    // Usiamo addPostFrameCallback per evitare errori se il widget è in fase di smontaggio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GameProvider>().clearCurrentState();
      }
    });
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Inizializza il gioco
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().initialize(date: widget.date);
    });
  }

  void _checkVictory(GameProvider gameProvider) {
    if (gameProvider.hasWon && !_victoryShown) {
      _victoryShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showVictoryDialog(context, gameProvider);
      });
    } else if (!gameProvider.hasWon) {
      _victoryShown = false; // Reset se si ricomincia
    }
  }

  Future<String?> _getHint() async {
    final gameProvider = context.read<GameProvider>();
    return await gameProvider.getHint();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          children: [
            Text('SEMANTICO',
                style: PopTheme.titleStyle.copyWith(fontSize: 24)),
            Consumer<GameProvider>(
              builder: (context, gp, _) {
                if (gp.dailyWordInfo == null) return const SizedBox.shrink();
                return Text(
                  'GIOCO #${gp.dailyWordInfo!.gameNumber} • ${gp.dailyWordInfo!.date}',
                  style: PopTheme.bodyStyle.copyWith(
                      fontSize: 12, fontWeight: FontWeight.bold),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: PopTheme.black),
            onPressed: () => _showInfoDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: PopTheme.black),
            onPressed: () => context.read<GameProvider>().refresh(),
          ),
        ],
        backgroundColor: PopTheme.white, // AppBar always matches theme background (Dark or White)
        elevation: 0,
        iconTheme: IconThemeData(color: PopTheme.black),
      ),
      backgroundColor: PopTheme.isDarkMode ? PopTheme.white : PopTheme.cyan, // Cyan in Light, Dark in Dark
      body: Container(
        // decoration: const BoxDecoration(
        //   gradient: LinearGradient(...) // RIMOSSO GRADIENTE
        // ),
        child: Consumer<GameProvider>(
          builder: (context, gameProvider, child) {
            _checkVictory(gameProvider);

            // Loading state
            if (gameProvider.isLoading && gameProvider.guesses.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Caricamento gioco...',
                        style: TextStyle(fontWeight: FontWeight.w500)),
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
                    Icon(Icons.cloud_off_rounded,
                        size: 80, color: Colors.red.shade300),
                    const SizedBox(height: 24),
                    const Text(
                      'Nessuna connessione',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Controlla che il server sia attivo',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () => gameProvider.refresh(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Riprova'),
                    ),
                  ],
                ),
              );
            }

            // Ordina i tentativi per Rank (migliori in alto)
            final sortedGuesses =
                gameProvider.guesses.where((g) => g.valid).toList();
            sortedGuesses.sort((a, b) {
              final rankA = a.rank ?? 999999;
              final rankB = b.rank ?? 999999;
              return rankA.compareTo(rankB);
            });

            // L'ultimo tentativo fatto (per mostrarlo in evidenza)
            final lastGuess = gameProvider.guesses.isNotEmpty
                ? gameProvider.guesses.last
                : null;

            return SafeArea(
              child: Column(
                children: [
                  // 1. INPUT FIELD (In alto)
                  if (!gameProvider.hasWon)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      color: PopTheme.white,
                      child: GuessInput(
                        onSubmit: (word) async {
                          await gameProvider.makeGuess(word);
                        },
                        isLoading: gameProvider.isLoading,
                        onHint: _getHint,
                      ),
                    ),

                  // 2. LAST GUESS (Subito sotto input)
                  if (lastGuess != null && !gameProvider.hasWon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: PopTheme.yellow,
                        border: Border(
                          bottom: BorderSide(color: PopTheme.black, width: 3),
                          top: BorderSide(color: PopTheme.black, width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ULTIMO TENTATIVO',
                            style: PopTheme.bodyStyle.copyWith(fontSize: 10),
                          ),
                          const SizedBox(height: 8),
                          GuessCard(guess: lastGuess),
                        ],
                      ),
                    ),

                  // 3. HEADER LISTA
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                    decoration: BoxDecoration(
                      color: PopTheme.magenta,
                      border: Border(
                        bottom: BorderSide(color: PopTheme.black, width: 3),
                        top: lastGuess == null
                            ? BorderSide(color: PopTheme.black, width: 3)
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 70,
                            child: Text('#',
                                style: PopTheme.bodyStyle
                                    .copyWith(color: PopTheme.white))),
                        Expanded(
                            child: Text('GUESS',
                                style: PopTheme.bodyStyle
                                    .copyWith(color: PopTheme.white))),
                        const SizedBox(width: 8),
                        SizedBox(
                            width: 140,
                            child: Text('PROX',
                                textAlign: TextAlign.right,
                                style: PopTheme.bodyStyle
                                    .copyWith(color: PopTheme.white))),
                      ],
                    ),
                  ),

                  // 4. LISTA STORICO (Ordinata per Rank)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: sortedGuesses.length,
                      itemBuilder: (context, index) {
                        return GuessCard(guess: sortedGuesses[index]);
                      },
                    ),
                  ),

                  // Messaggio vittoria (se vinto) - RIMOSSO, ora c'è il dialog
                  // Manteniamo solo un piccolo banner o nulla?
                  // Meglio nulla per pulizia, il dialog basta.
                  if (gameProvider.hasWon)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emoji_events_rounded,
                              color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Hai vinto in ${gameProvider.attemptCount} tentativi!',
                            style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                  // Errore
                  if (gameProvider.errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.red.shade100,
                      child: Text(
                        gameProvider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showVictoryDialog(BuildContext context, GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (context) => VictoryDialog(
        attemptCount: gameProvider.attemptCount,
        dailyWordInfo: gameProvider.dailyWordInfo,
        onClose: () => Navigator.pop(context),
        onShare: () {
          final text =
              'Semantico #${gameProvider.dailyWordInfo?.gameNumber ?? ""}\n'
              '🏆 Ho indovinato in ${gameProvider.attemptCount} tentativi!\n\n'
              'Gioca anche tu!';
          Clipboard.setData(ClipboardData(text: text));
        },
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: PopTheme.boxDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'COME SI GIOCA',
                  style: PopTheme.titleStyle.copyWith(fontSize: 24),
                ),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 OBIETTIVO',
                      style: PopTheme.bodyStyle
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Indovina la parola segreta! Ogni tentativo riceve un punteggio di vicinanza.',
                      style: PopTheme.bodyStyle,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '🌡️ TEMPERATURE',
                      style: PopTheme.bodyStyle
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('GHIACCIATO', PopTheme.cyan),
                    _buildInfoRow('TIEPIDO', PopTheme.yellow),
                    _buildInfoRow('CALDO', Colors.orangeAccent.shade700),
                    _buildInfoRow('FUOCO', PopTheme.magenta),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: PopTheme.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: PopTheme.radius,
                    ),
                  ),
                  child: Text('CAPITO!',
                      style: PopTheme.bodyStyle.copyWith(color: PopTheme.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              border: PopTheme.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: PopTheme.bodyStyle),
        ],
      ),
    );
  }
}
