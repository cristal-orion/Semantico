import 'package:flutter/material.dart';
import '../theme/pop_theme.dart';

/// Widget per input parola in Shot Mode
class ShotInput extends StatefulWidget {
  final Function(String) onSubmit;
  final bool isLoading;

  const ShotInput({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<ShotInput> createState() => _ShotInputState();
}

class _ShotInputState extends State<ShotInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ShotInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading) {
      // Il caricamento è finito, ridiamo il focus all'input dopo il frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint("Restoring focus to shot input field");
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            // NON usare readOnly o enabled - lascia il campo sempre attivo!
            // Il blocco dell'input è gestito in _submit() come fa GuessInput
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
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
              filled: true,
              fillColor: PopTheme.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: PopTheme.bodyStyle.copyWith(fontSize: 18),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 12),
        // Pulsante o loading indicator
        if (widget.isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: PopTheme.black,
              ),
            ),
          )
        else
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
              onPressed: _submit,
            ),
          ),
      ],
    );
  }
}
