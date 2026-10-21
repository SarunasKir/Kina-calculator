import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kina_app/src/providers.dart';

/// NCSOFT's Aion 2 Global operating policy.
final Uri ncsoftPolicyUrl = Uri.parse(
  'https://www.plaync.com/policy/operation/aion2global/en',
);

/// The help guides (requirement FR-20).
enum HelpTopic {
  /// How VAT is added.
  vat('Understanding VAT'),

  /// How payment fees are added.
  fees('Payment processing fees'),

  /// The risks of buying from third-party sellers.
  risks('Know the risks');

  const HelpTopic(this.title);

  /// The guide's title.
  final String title;
}

/// One titled block of a help guide.
typedef HelpSection = ({String heading, List<String> lines});

/// The text of each guide, taken from the v55 help artwork.
const Map<HelpTopic, List<HelpSection>> helpText = {
  HelpTopic.vat: [
    (
      heading: 'How VAT affects your purchase',
      lines: ['VAT is a percentage added to the seller subtotal.'],
    ),
    (
      heading: 'VAT rate',
      lines: [
        'Enter the applicable VAT percentage.',
        'Enter 0 if VAT is not charged.',
      ],
    ),
    (
      heading: 'Calculation',
      lines: [
        'VAT = seller subtotal × VAT percentage.',
        'The amount after VAT is subtotal + VAT.',
      ],
    ),
    (
      heading: 'Example',
      lines: [
        '€ 100.00 × 21% = € 21.00 VAT',
        'Subtotal including VAT: € 121.00',
      ],
    ),
    (
      heading: 'Good to know',
      lines: [
        'Payment fees may be added after VAT.',
        'Use the rate that applies to your purchase.',
      ],
    ),
  ],
  HelpTopic.fees: [
    (
      heading: 'How payment fees affect your purchase',
      lines: ['The selected payment method can add two charges.'],
    ),
    (
      heading: 'Percentage fee',
      lines: [
        'Calculated on the subtotal including VAT.',
        'Example: 3.9% of € 121.00 = € 4.72.',
      ],
    ),
    (
      heading: 'Fixed fee',
      lines: [
        'A flat charge applied once per transaction.',
        'It is added to the percentage fee.',
      ],
    ),
    (
      heading: 'Example',
      lines: ['€ 121.00 × 3.9% + € 0.99 = € 5.71', 'Total payment fee: € 5.71'],
    ),
    (
      heading: 'Good to know',
      lines: [
        'Enter 0 when a fee does not apply.',
        'Each payment method saves its own fees.',
      ],
    ),
  ],
  HelpTopic.risks: [
    (
      heading: 'Real-money trading',
      lines: [
        'Buying Kina from unauthorized third-party sellers can violate',
        "NCSOFT's Aion 2 Global operating policy.",
      ],
    ),
    (
      heading: 'Published RMT penalty schedule',
      lines: [
        'First violation: 30 days account suspension.',
        'Second violation: 90 days account suspension.',
        'Attempted RMT or advertising can also carry penalties.',
        'Enforcement can be more severe depending on circumstances.',
      ],
    ),
    (
      heading: 'Other risks',
      lines: [
        'Buying from a third party may also expose you to scams or lost funds.',
        'Official rules can change; check the current policy before deciding.',
        'Policy reference: Aion 2 Global (reviewed 20 October 2026).',
      ],
    ),
  ],
};

/// Shows the guide for [topic] in a dialog.
Future<void> showHelp(BuildContext context, HelpTopic topic) =>
    showDialog<void>(
      context: context,
      builder: (context) => HelpDialog(topic: topic),
    );

/// A help guide in a dialog.
class HelpDialog extends ConsumerWidget {
  /// Creates the dialog.
  const HelpDialog({required this.topic, super.key});

  /// The guide to show.
  final HelpTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(topic.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final section in helpText[topic]!) ...[
                Text(section.heading, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                for (final line in section.lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(line),
                  ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (topic == HelpTopic.risks)
          TextButton.icon(
            key: const Key('openPolicy'),
            onPressed: () => ref.read(linkOpenerProvider)(ncsoftPolicyUrl),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open the operating policy'),
          ),
        FilledButton(
          key: const Key('closeHelp'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
