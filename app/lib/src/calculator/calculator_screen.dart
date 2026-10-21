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
                compact: true,
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
            KeyedSubtree(
              key: ValueKey('payment-${s.selectedPayment}-${s.paymentMethods}'),
              child: DropdownButtonFormField<int>(
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
            ),
            _PaymentActions(settings: s),
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
            if (view.cheapestLine case final line?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  line,
                  key: const Key('cheapest'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('addSeller'),
                  onPressed: s.sellers.length >= CalculatorSettings.maxSellers
                      ? null
                      : () => edit(addSeller),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Add seller (${s.sellers.length} of '
                    '${CalculatorSettings.maxSellers})',
                  ),
                ),
                FilledButton.tonalIcon(
                  key: const Key('fetchAll'),
                  onPressed: () => _fetch(context, ref),
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: const Text('Fetch prices'),
                ),
              ],
            ),
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
    methods[selectedIndex(s)] = method;
    return s.copyWith(paymentMethods: methods);
  }
}

/// Buttons to rename, add and remove payment methods.
class _PaymentActions extends ConsumerWidget {
  const _PaymentActions({required this.settings});

  final CalculatorSettings settings;

  Future<String?> _askName(BuildContext context, {String initial = ''}) =>
      showDialog<String>(
        context: context,
        builder: (_) => _NameDialog(initial: initial),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(settingsProvider.notifier);
    final s = settings;
    return Wrap(
      spacing: 8,
      children: [
        TextButton.icon(
          key: const Key('addPayment'),
          onPressed: () async {
            final name = await _askName(context);
            if (name != null) {
              await controller.edit((s) => addPaymentMethod(s, name));
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Add method'),
        ),
        TextButton.icon(
          key: const Key('renamePayment'),
          onPressed: () async {
            final name = await _askName(context, initial: s.payment.name);
            if (name != null) {
              await controller.edit((s) => renamePaymentMethod(s, name));
            }
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Rename'),
        ),
        TextButton.icon(
          key: const Key('removePayment'),
          onPressed: s.paymentMethods.length <= 1
              ? null
              : () => controller.edit(removePaymentMethod),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Remove'),
        ),
      ],
    );
  }
}

/// Asks for a payment method name.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Payment method name'),
    content: TextField(
      key: const Key('paymentName'),
      controller: _controller,
      autofocus: true,
      maxLength: maxPaymentNameLength,
      decoration: const InputDecoration(labelText: 'Name'),
      onSubmitted: (v) => Navigator.pop(context, v),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('savePaymentName'),
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('Save'),
      ),
    ],
  );
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
    final seller = outcome.seller;
    final controller = ref.read(settingsProvider.notifier);
    void setSeller(Seller seller) => controller.edit((s) {
      final sellers = [...s.sellers];
      sellers[index] = seller;
      return s.copyWith(sellers: sellers);
    });
    final source = seller.source ?? const PriceSource(url: '');
    void setSource(PriceSource next) =>
        setSeller(seller.copyWith(source: next));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldPair(
          first: SyncedTextField(
            key: Key('sellerName$index'),
            label: 'Seller',
            numeric: false,
            value: seller.name,
            onChanged: (v) => setSeller(seller.copyWith(name: v)),
          ),
          second: SyncedTextField(
            key: Key('sellerPrice$index'),
            label: 'Price per 1M',
            prefix: symbol,
            value: seller.pricePerMillion,
            onChanged: (v) => setSeller(seller.copyWith(pricePerMillion: v)),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                view.sellerLine(outcome),
                key: Key('sellerResult$index'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            IconButton(
              key: Key('removeSeller$index'),
              tooltip: 'Remove ${seller.name}',
              onPressed: view.sellers.length <= CalculatorSettings.minSellers
                  ? null
                  : () => controller.edit((s) => removeSeller(s, index)),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        ExpansionTile(
          key: Key('sellerDetails$index'),
          title: const Text('Site and fees'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: [
            FieldPair(
              first: SyncedTextField(
                key: Key('sellerFee$index'),
                label: 'Extra site fee',
                suffix: '%',
                value: seller.extraFeePercent,
                onChanged: (v) =>
                    setSeller(seller.copyWith(extraFeePercent: v)),
              ),
              second: SyncedTextField(
                key: Key('sellerFixed$index'),
                label: 'Extra fixed fee',
                prefix: symbol,
                value: seller.extraFixedFee,
                onChanged: (v) => setSeller(seller.copyWith(extraFixedFee: v)),
              ),
            ),
            SyncedTextField(
              key: Key('sourceUrl$index'),
              label: 'Site address',
              numeric: false,
              value: source.url,
              onChanged: (v) => setSource(source.copyWith(url: v)),
            ),
            FieldPair(
              first: DropdownButtonFormField<SourceKind>(
                key: Key('sourceKind$index'),
                initialValue: source.kind,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Read as'),
                items: const [
                  DropdownMenuItem(
                    value: SourceKind.auto,
                    child: Text('Automatic'),
                  ),
                  DropdownMenuItem(
                    value: SourceKind.json,
                    child: Text('JSON address'),
                  ),
                  DropdownMenuItem(
                    value: SourceKind.css,
                    child: Text('Page selector'),
                  ),
                ],
                onChanged: (k) => setSource(source.copyWith(kind: k)),
              ),
              second: source.kind == SourceKind.auto
                  ? const SizedBox.shrink()
                  : SyncedTextField(
                      key: Key('sourceRule$index'),
                      label: source.kind == SourceKind.json
                          ? 'JSON path, e.g. data.price'
                          : 'CSS selector, e.g. .price',
                      numeric: false,
                      value: source.rule,
                      onChanged: (v) => setSource(source.copyWith(rule: v)),
                    ),
            ),
            FieldPair(
              first: DropdownButtonFormField<String>(
                key: Key('sourceUnit$index'),
                initialValue: _units.contains(source.unitMillions)
                    ? source.unitMillions
                    : '1',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Price is for'),
                items: [
                  for (final u in _units)
                    DropdownMenuItem(
                      value: u,
                      child: Text(u == '1000' ? '1B Kina' : '${u}M Kina'),
                    ),
                ],
                onChanged: (u) => setSource(source.copyWith(unitMillions: u)),
              ),
              second: DropdownButtonFormField<String>(
                key: Key('sourceCurrency$index'),
                initialValue: source.currency,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Site currency'),
                items: [
                  for (final c in {
                    ...view.settings.ratesPerEur.keys,
                    source.currency,
                  })
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (c) => setSource(source.copyWith(currency: c)),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                key: Key('fetchSeller$index'),
                onPressed: () => _fetch(context, ref, index),
                icon: const Icon(Icons.cloud_download_outlined),
                label: const Text('Fetch price'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

const _units = ['1', '10', '100', '1000'];

Future<void> _fetch(BuildContext context, WidgetRef ref, [int? only]) async {
  final messenger = ScaffoldMessenger.of(context);
  final messages = await ref
      .read(settingsProvider.notifier)
      .fetchSellerPrices(only: only);
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        messages.isEmpty ? 'Add a site address first' : messages.join('\n'),
      ),
    ),
  );
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
