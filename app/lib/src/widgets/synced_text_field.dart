import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A text field that shows [value] and reports edits, and also picks up
/// changes made elsewhere (a currency switch or a reset) without losing what
/// the user is typing.
class SyncedTextField extends StatefulWidget {
  /// Creates the field. [onChanged] fires on every keystroke; [onCommitted]
  /// fires when the user presses enter or leaves the field.
  const SyncedTextField({
    required this.label,
    required this.value,
    this.onChanged,
    this.onCommitted,
    this.numeric = true,
    this.prefix,
    this.suffix,
    super.key,
  });

  /// Field label.
  final String label;

  /// The current value from the app state.
  final String value;

  /// Called with the text on every edit.
  final ValueChanged<String>? onChanged;

  /// Called with the text when editing is done.
  final ValueChanged<String>? onCommitted;

  /// Whether to show a number keyboard and allow only digits and separators.
  final bool numeric;

  /// Text before the input, such as a currency symbol.
  final String? prefix;

  /// Text after the input, such as `%`.
  final String? suffix;

  @override
  State<SyncedTextField> createState() => _SyncedTextFieldState();
}

class _SyncedTextFieldState extends State<SyncedTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        widget.onCommitted?.call(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(SyncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    focusNode: _focus,
    decoration: InputDecoration(
      labelText: widget.label,
      prefixText: widget.prefix == null ? null : '${widget.prefix} ',
      suffixText: widget.suffix,
    ),
    keyboardType: widget.numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    inputFormatters: widget.numeric
        ? [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))]
        : null,
    onChanged: widget.onChanged,
    onSubmitted: widget.onCommitted,
  );
}
