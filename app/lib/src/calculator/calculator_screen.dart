import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kina_app/src/calculator/calculator_logic.dart';
import 'package:kina_app/src/calculator/calculator_view.dart';
import 'package:kina_app/src/export/csv.dart';
import 'package:kina_app/src/export/export_action.dart';
import 'package:kina_app/src/format.dart';
import 'package:kina_app/src/help/help.dart';
import 'package:kina_app/src/providers.dart';
import 'package:kina_app/src/rates/rate_sync.dart';
import 'package:kina_app/src/theme.dart';
import 'package:kina_app/src/widgets/section_card.dart';
import 'package:kina_app/src/widgets/synced_text_field.dart';
import 'package:kina_data/kina_data.dart';

/// Width from which inputs and results sit side by side.
const wideLayoutWidth = 900.0;

/// The main calculator: RMT cost against the official Quna route.
class CalculatorScreen extends ConsumerWidget {
  /// Creates the screen.
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(calculatorViewProvider);
    return view.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Could not load settings: $error')),
      data: (view) => LayoutBuilder(
        builder: (context, constraints) {
          final inputs = _Inputs(view: view);
          final results = _Results(view: view);
          if (constraints.maxWidth >= wideLayoutWidth) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: inputs),
                  const SizedBox(width: 24),
                  Expanded(child: results),
                ],
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [inputs, const SizedBox(height: 16), results],
                ),
              ),
              _SummaryBar(view: view),
            ],
          );
        },
      ),
    );
  }
}

/// On phones, keeps the RMT total and the savings in view while scrolling.
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.view});

  final CalculatorView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const Key('summaryBar'),
      color: theme.colorScheme.secondaryContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ResultRow(
                label: 'RMT total',
                value: view.money(view.main.rmt.total),
                emphasize: true,
              ),
              const SizedBox(height: 4),
              Text(
                view.savingsLine,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: !view.main.officialValid
                      ? null
                      : view.main.savings.sign >= 0
                      ? savingsGood
                      : savingsBad,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Inputs extends ConsumerWidget {
  const _Inputs({required this.view});

  final CalculatorView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = view.settings;
    final controller = ref.read(settingsProvider.notifier);
    void edit(CalculatorSettings Function(CalculatorSettings) change) =>
        controller.edit(change);
    final symbol = currencySymbols[s.currency] ?? s.currency;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'RMT purchase',
          children: [
            FieldPair(
              first: SyncedTextField(
                key: const Key('amount'),
                label: 'Kina (millions)',
                value: s.amountMillions,
                onChanged: (v) => edit((s) => s.copyWith(amountMillions: v)),
              ),
              second: SyncedTextField(
                key: const Key('price'),
                label: 'RMT price per 1M',
                prefix: symbol,
                value: s.pricePerMillion,
                onChanged: (v) => edit((s) => s.copyWith(pricePerMillion: v)),
              ),
            ),
            DropdownButtonFormField<int>(
              key: const Key('payment'),
              initialValue: s.selectedPayment,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Payment method'),
              items: [
                for (var i = 0; i < s.paymentMethods.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(s.paymentMethods[i].name),
                  ),
              ],
              onChanged: (i) => edit((s) => s.copyWith(selectedPayment: i)),
            ),
            FieldPair(
              first: SyncedTextField(
                key: const Key('feePercent'),
                label: 'Payment fee',
                suffix: '%',
                value: s.payment.feePercent,
                onInfo: () => showHelp(context, HelpTopic.fees),
                onChanged: (v) => edit(
                  (s) => _withPayment(s, s.payment.copyWith(feePercent: v)),
                ),
              ),
              second: SyncedTextField(
                key: const Key('fixedFee'),
                label: 'Fixed fee',
                prefix: symbol,
                value: s.payment.fixedFee,
                onChanged: (v) => edit(
                  (s) => _withPayment(s, s.payment.copyWith(fixedFee: v)),
                ),
              ),
            ),
            SyncedTextField(
              key: const Key('vat'),
              label: 'VAT',
              suffix: '%',
              value: s.vatPercent,
              onInfo: () => showHelp(context, HelpTopic.vat),
              onChanged: (v) => edit((s) => s.copyWith(vatPercent: v)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Official Quna exchange',
          children: [
            FieldPair(
              first: SyncedTextField(
                key: const Key('qunaPerPack'),
                label: 'Quna per pack',
                value: s.qunaPerPack,
                onChanged: (v) => edit((s) => s.copyWith(qunaPerPack: v)),
              ),
              second: SyncedTextField(
                key: const Key('packPrice'),
                label: 'Pack price',
                prefix: symbol,
                value: s.packPrice,
                onChanged: (v) => edit((s) => s.copyWith(packPrice: v)),
              ),
            ),
            FieldPair(
              first: SyncedTextField(
                key: const Key('qunaPerChest'),
                label: 'Quna per chest',
                value: s.qunaPerChest,
                onChanged: (v) => edit((s) => s.copyWith(qunaPerChest: v)),
              ),
              second: SyncedTextField(
                key: const Key('millionsPerChest'),
                label: 'Kina per chest (millions)',
                value: s.millionsPerChest,
                onChanged: (v) => edit((s) => s.copyWith(millionsPerChest: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Seller comparison',
          children: [
            for (var i = 0; i < view.sellers.length; i++)
              _SellerRow(index: i, view: view, symbol: symbol),
          ],
        ),
        const SizedBox(height: 16),
        _CurrencyCard(view: view),
      ],
    );
  }

  static CalculatorSettings _withPayment(
    CalculatorSettings s,
    PaymentMethod method,
  ) {
    final methods = [...s.paymentMethods];
    methods[methods.indexOf(s.payment)] = method;
    return s.copyWith(paymentMethods: methods);
  }
}

class _SellerRow extends ConsumerWidget {
  const _SellerRow({
    required this.index,
    required this.view,
    required this.symbol,
  });

  final int index;
  final CalculatorView view;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcome = view.sellers[index];
    final controller = ref.read(settingsProvider.notifier);
    void setSeller(Seller seller) => controller.edit((s) {
      final sellers = [...s.sellers];
      sellers[index] = seller;
      return s.copyWith(sellers: sellers);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldPair(
          first: SyncedTextField(
            key: Key('sellerName$index'),
            label: 'Seller',
            numeric: false,
            value: outcome.seller.name,
            onChanged: (v) => setSeller(
              Seller(name: v, pricePerMillion: outcome.seller.pricePerMillion),
            ),
          ),
          second: SyncedTextField(
            key: Key('sellerPrice$index'),
            label: 'Price per 1M',
            prefix: symbol,
            value: outcome.seller.pricePerMillion,
            onChanged: (v) => setSeller(
              Seller(name: outcome.seller.name, pricePerMillion: v),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          view.sellerLine(outcome),
          key: Key('sellerResult$index'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _CurrencyCard extends ConsumerStatefulWidget {
  const _CurrencyCard({required this.view});

  final CalculatorView view;

  @override
  ConsumerState<_CurrencyCard> createState() => _CurrencyCardState();
}

class _CurrencyCardState extends ConsumerState<_CurrencyCard> {
  bool _syncing = false;

  Future<void> _sync() async {
    setState(() => _syncing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final published = await ref.read(settingsProvider.notifier).syncRates();
      messenger.showSnackBar(
        SnackBar(content: Text('Rates updated (ECB, ${published.date})')),
      );
    } on RateSyncException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Sync failed: $e. Your rates are unchanged.')),
      );
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.view.settings;
    final controller = ref.read(settingsProvider.notifier);
    final codes = s.ratesPerEur.keys.toList();
    final pair = widget.view.pairRate;

    return SectionCard(
      title: 'Currency',
      children: [
        FieldPair(
          first: DropdownButtonFormField<String>(
            key: const Key('currency'),
            initialValue: s.currency,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Calculator currency'),
            items: [
              for (final c in codes)
                DropdownMenuItem(
                  value: c,
                  child: Text('$c ${currencyNames[c] ?? ''}'.trim()),
                ),
            ],
            onChanged: (c) => controller.edit((s) => changeCurrency(s, c!)),
          ),
          second: DropdownButtonFormField<String>(
            key: const Key('targetCurrency'),
            initialValue: s.targetCurrency,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Convert to'),
            items: [
              for (final c in codes) DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (c) =>
                controller.edit((s) => s.copyWith(targetCurrency: c)),
          ),
        ),
        SyncedTextField(
          key: const Key('rate'),
          label: '1 ${s.currency} in ${s.targetCurrency}',
          value: pair == null ? '' : pair.toStringAsFixed(4),
          onCommitted: (v) => controller.edit((s) => setManualRate(s, v)),
        ),
        Row(
          children: [
            FilledButton.tonalIcon(
              key: const Key('syncRates'),
              onPressed: _syncing ? null : _sync,
              icon: const Icon(Icons.sync),
              label: Text(_syncing ? 'Syncing…' : 'Sync online rates'),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(rateStatus(s), key: const Key('rateStatus'))),
          ],
        ),
      ],
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.view});

  final CalculatorView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = view.main;
    final theme = Theme.of(context);
    final good = r.officialValid && r.savings.sign >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'RMT cost',
          children: [
            ResultRow(
              label: 'Seller subtotal',
              value: view.money(r.rmt.subtotal),
            ),
            ResultRow(label: 'VAT', value: view.money(r.rmt.vat)),
            ResultRow(label: 'Payment fee', value: view.money(r.rmt.fee)),
            ResultRow(
              key: const Key('rmtTotal'),
              label: 'RMT total',
              value: view.money(r.rmt.total),
              emphasize: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Official Quna route',
          children: [
            ResultRow(
              key: const Key('quna'),
              label: 'Quna needed',
              value: r.officialValid ? formatQuna(r.qunaRequired) : '--',
            ),
            ResultRow(
              key: const Key('official'),
              label: 'Official cost',
              value: r.officialValid
                  ? view.money(r.officialCost)
                  : 'Enter a valid Quna conversion',
              emphasize: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          color: !r.officialValid
              ? null
              : good
              ? savingsGoodPanel
              : savingsBadPanel,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  view.savingsLine,
                  key: const Key('savings'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    color: !r.officialValid
                        ? null
                        : good
                        ? savingsGood
                        : savingsBad,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  view.hasAmount
                      ? 'Effective RMT price: '
                            '${view.money(r.effectiveRate)} per 1M Kina'
                      : 'Effective RMT price: --',
                  key: const Key('effective'),
                ),
                Text(
                  r.officialValid && view.hasAmount
                      ? 'Break-even RMT price: '
                            '${view.money(r.breakEvenRate)} per 1M Kina'
                      : 'Break-even RMT price: --',
                  key: const Key('breakEven'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              key: const Key('exportCalculation'),
              onPressed: () => exportCsv(
                context,
                ref,
                stem: 'kina_comparison',
                csv: calculatorCsv(view),
              ),
              icon: const Icon(Icons.download),
              label: const Text('Export CSV'),
            ),
            OutlinedButton.icon(
              key: const Key('reset'),
              onPressed: () => _confirmReset(context, ref),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset to defaults'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Calculations run on this device · rates sync only on request · '
          'third-party trades carry risk',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset the calculator?'),
        content: const Text(
          'All fields, fees, sellers and rates go back to their defaults.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmReset'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(settingsProvider.notifier).reset();
    }
  }
}
