import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shot_provider.dart';
import '../theme/pop_theme.dart';
import '../widgets/shot_clue_card.dart';
import '../widgets/shot_input.dart';
import '../widgets/shot_stats_widget.dart';
import '../widgets/shot_victory_dialog.dart';
import '../widgets/vector_background.dart';

class ShotGameScreen extends StatefulWidget {
  const ShotGameScreen({super.key});

  @override
  State<ShotGameScreen> createState() => _ShotGameScreenState();
}

class _ShotGameScreenState extends State<ShotGameScreen> {
  @override
  void initState() {
    super.initState();
    // Avvia nuova partita se non ce n'è una attiva
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ShotProvider>();
      if (provider.currentGame == null) {
        provider.startNewGame();
      }
    });
  }

  void _handleGuess(String word) async {
    final provider = context.read<ShotProvider>();
    final result = await provider.makeGuess(word);

    if (result != null && result.correct && mounted) {
      // Solo quando vince chiudiamo la tastiera e mostriamo il dialog
      FocusScope.of(context).unfocus();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ShotVictoryDialog(
          targetWord: result.targetWord ?? word,
          onNewGame: () {
            provider.startNewGame();
          },
        ),
      );
    }
  }

  void _showSkipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Arrenditi?', style: PopTheme.headingStyle),
        content: Text(
          'Vuoi saltare questa parola?\nLa partita verrà contata come non completata.',
          style: PopTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla', style: PopTheme.bodyStyle),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<ShotProvider>();
              await provider.skipGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PopTheme.magenta,
            ),
            child: Text('Salta', style: PopTheme.bodyStyle.copyWith(color: PopTheme.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SHOT MODE', style: PopTheme.headingStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: PopTheme.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Pulsante Skip
          IconButton(
            icon: Icon(Icons.skip_next_rounded, color: PopTheme.black),
            onPressed: () {
              _showSkipDialog(context);
            },
            tooltip: 'Salta parola',
          ),
          // Pulsante Statistiche
          IconButton(
            icon: Icon(Icons.bar_chart, color: PopTheme.black),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => Consumer<ShotProvider>(
                  builder: (context, provider, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: ShotStatsWidget(stats: provider.stats),
                  ),
                ),
              );
            },
            tooltip: 'Statistiche',
          ),
        ],
      ),
      backgroundColor: PopTheme.cyan,
      body: Consumer<ShotProvider>(
        builder: (context, provider, child) {
          // Mostra loading completo SOLO al primo caricamento
          if (provider.isLoading && provider.currentGame == null) {
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

          if (provider.currentGame == null) {
            return Center(child: CircularProgressIndicator(color: PopTheme.black));
          }

          // USA SafeArea come GameScreen
          return SafeArea(
            child: Column(
              children: [
                // 1. INPUT FIELD (In alto)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  color: PopTheme.white,
                  child: ShotInput(
                    onSubmit: _handleGuess,
                    isLoading: provider.isLoading,
                  ),
                ),

                // 2. Area Indizi
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: List.generate(
                        provider.currentGame!.clueWords.length,
                        (index) => ShotClueCard(
                          word: provider.currentGame!.clueWords[index],
                          index: index,
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Area Tentativi - RESPONSIVE
                if (provider.guesses.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PopTheme.grey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PopTheme.black, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TENTATIVI:',
                            style: PopTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: provider.guesses.length,
                              itemBuilder: (context, index) {
                                final guess = provider.guesses[provider.guesses.length - 1 - index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    guess,
                                    style: PopTheme.bodyStyle.copyWith(
                                      color: PopTheme.black.withOpacity(0.6),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
