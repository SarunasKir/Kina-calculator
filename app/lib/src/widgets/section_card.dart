import 'package:flutter/material.dart';

/// A titled card grouping related fields or results.
class SectionCard extends StatelessWidget {
  /// Creates the card.
  const SectionCard({required this.title, required this.children, super.key});

  /// Section title.
  final String title;

  /// Section content, laid out top to bottom with even spacing.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          for (final child in children) ...[const SizedBox(height: 12), child],
        ],
      ),
    ),
  );
}

/// Lays out two fields side by side when there is room, else stacked.
class FieldPair extends StatelessWidget {
  /// Creates the pair.
  const FieldPair({required this.first, required this.second, super.key});

  /// The left (or top) field.
  final Widget first;

  /// The right (or bottom) field.
  final Widget second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < 280
        ? Column(children: [first, const SizedBox(height: 12), second])
        : Row(
            children: [
              Expanded(child: first),
              const SizedBox(width: 12),
              Expanded(child: second),
            ],
          ),
  );
}

/// A label with a value on the right, for results.
class ResultRow extends StatelessWidget {
  /// Creates the row.
  const ResultRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    super.key,
  });

  /// What the value is.
  final String label;

  /// The value.
  final String value;

  /// Whether to show the row in bold.
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyLarge;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
