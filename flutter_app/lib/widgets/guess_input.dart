import 'package:flutter/material.dart';
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
    return Container(
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
            IconButton(
              icon: Icon(Icons.lightbulb_outline_rounded,
                  color: PopTheme.black),
              onPressed: () async {
                if (widget.onHint != null) {
                  await _getHint();
                }
              },
              tooltip: 'Suggerimento',
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
    );
  }
}
