import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/pop_theme.dart';

/// Widget per input parola
class GuessInput extends StatefulWidget {
  final Function(String) onSubmit;
  final bool isLoading;
  final Future<String?> Function()? onHint;

  const GuessInput({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.onHint,
  });

  @override
  State<GuessInput> createState() => _GuessInputState();
}

class _GuessInputState extends State<GuessInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showHintTooltip = false;
  final GlobalKey _hintButtonKey = GlobalKey();


  @override
  void initState() {
    super.initState();
    _checkFirstTimeHint();
  }

  Future<void> _checkFirstTimeHint() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenHint = prefs.getBool('has_seen_hint_tooltip') ?? false;

    if (!hasSeenHint && mounted) {
      // Show tooltip after a brief delay
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          _showHintTooltip = true;
        });
        // Auto-hide after 5 seconds
        await Future.delayed(const Duration(seconds: 5));
        if (mounted) {
          setState(() {
            _showHintTooltip = false;
          });
          await prefs.setBool('has_seen_hint_tooltip', true);
        }
      }
    }
  }

  void _dismissHintTooltip() async {
    if (_showHintTooltip) {
      setState(() {
        _showHintTooltip = false;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_hint_tooltip', true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GuessInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading) {
      // Il caricamento è finito, ridiamo il focus all'input dopo il frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint("Restoring focus to input field");
          _focusNode.requestFocus();
        }
      });
    }
  }

  void _submit() {
    final word = _controller.text.trim();
    if (word.isEmpty || widget.isLoading) return;

    widget.onSubmit(word);
    _controller.clear();
    _focusNode.requestFocus();
  }

  Future<void> _getHint() async {
    if (widget.onHint != null) {
      final hint = await widget.onHint!();
      if (hint != null && mounted) {
        _controller.text = hint;
        _focusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hint tooltip
        if (_showHintTooltip)
          GestureDetector(
            onTap: _dismissHintTooltip,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: PopTheme.yellow,
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
              child: Row(
                children: [
                  Icon(Icons.lightbulb_rounded, color: PopTheme.black, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bloccato? Tocca la lampadina per ricevere un suggerimento!',
                      style: PopTheme.bodyStyle.copyWith(fontSize: 13),
                    ),
                  ),
                  Icon(Icons.close, color: PopTheme.black, size: 18),
                ],
              ),
            ),
          ),
        Container(
          decoration: PopTheme.boxDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    style: PopTheme.bodyStyle.copyWith(fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Scrivi una parola...',
                      hintStyle:
                          PopTheme.bodyStyle.copyWith(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ),
              if (widget.isLoading)
                Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: PopTheme.black,
                    ),
                  ),
                )
              else ...[
                Container(
                  key: _hintButtonKey,
                  decoration: _showHintTooltip
                      ? BoxDecoration(
                          color: PopTheme.yellow.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        )
                      : null,
                  child: IconButton(
                    icon: Icon(Icons.lightbulb_outline_rounded,
                        color: PopTheme.black),
                    onPressed: () async {
                      _dismissHintTooltip();
                      if (widget.onHint != null) {
                        await _getHint();
                      }
                    },
                    tooltip: 'Suggerimento',
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: PopTheme.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_upward_rounded,
                        color: PopTheme.yellow),
                    onPressed: _submit,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
