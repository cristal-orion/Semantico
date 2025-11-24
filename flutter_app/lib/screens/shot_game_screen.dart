import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shot_provider.dart';
import '../theme/pop_theme.dart';
import '../widgets/shot_clue_card.dart';
import '../widgets/shot_stats_widget.dart';
import '../widgets/shot_victory_dialog.dart';

class ShotGameScreen extends StatefulWidget {
  const ShotGameScreen({super.key});

  @override
  State<ShotGameScreen> createState() => _ShotGameScreenState();
}

class _ShotGameScreenState extends State<ShotGameScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleGuess() async {
    final word = _controller.text.trim();
    if (word.isEmpty) return;

    final provider = context.read<ShotProvider>();
    final result = await provider.makeGuess(word);

    if (result != null) {
      _controller.clear();
      _focusNode.requestFocus();

      if (result.correct && mounted) {
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: PopTheme.red,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PopTheme.white,
      appBar: AppBar(
        title: Text('SHOT MODE', style: PopTheme.headingStyle),
        backgroundColor: PopTheme.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: PopTheme.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
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
          ),
        ],
      ),
      body: Consumer<ShotProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentGame == null) {
            return Center(child: CircularProgressIndicator(color: PopTheme.black));
          }

          if (provider.currentGame == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () => provider.startNewGame(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PopTheme.blue,
                  foregroundColor: PopTheme.white,
                ),
                child: const Text('INIZIA PARTITA'),
              ),
            );
          }

          return Column(
            children: [
              // Area Indizi
              Expanded(
                flex: 3,
                child: Center(
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
              ),

              // Area Tentativi
              if (provider.guesses.isNotEmpty)
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PopTheme.grey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PopTheme.black),
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
                              // Mostra in ordine inverso (più recente in alto)
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

              // Area Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PopTheme.white,
                  boxShadow: [
                    BoxShadow(
                      color: PopTheme.black.withOpacity(0.1),
                      offset: const Offset(0, -4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Indovina la parola...',
                          hintStyle: PopTheme.bodyStyle.copyWith(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: PopTheme.black, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: PopTheme.black, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: PopTheme.blue, width: 3),
                          ),
                          filled: true,
                          fillColor: PopTheme.white,
                        ),
                        style: PopTheme.bodyStyle,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleGuess(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: PopTheme.green,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PopTheme.black, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: PopTheme.black,
                            offset: const Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, color: PopTheme.white),
                        onPressed: _handleGuess,
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
}
