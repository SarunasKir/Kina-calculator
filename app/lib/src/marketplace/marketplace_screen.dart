import 'package:clock/clock.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kina_app/src/calculator/calculator_screen.dart';
import 'package:kina_app/src/export/csv.dart';
import 'package:kina_app/src/export/export_action.dart';
import 'package:kina_app/src/format.dart';
import 'package:kina_app/src/marketplace/marketplace_view.dart';
import 'package:kina_app/src/providers.dart';
import 'package:kina_app/src/widgets/confirm.dart';
import 'package:kina_app/src/widgets/section_card.dart';
import 'package:kina_data/kina_data.dart';
import 'package:uuid/uuid.dart';

/// Values marketplace items priced in Kina and keeps a purchase journal
/// (requirements FR-12 to FR-15).
class MarketplaceScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _item = TextEditingController();
  final _price = TextEditingController(text: '25m');

  @override
  void initState() {
    super.initState();
    _price.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _item.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save(MarketplaceView view) async {
    final entry = view.entry(
      id: const Uuid().v4(),
      date: clock.now(),
      item: JournalRepository.cleanItemName(_item.text),
    );
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(journalProvider.notifier).add(entry);
    messenger.showSnackBar(
      SnackBar(content: Text('Saved to the journal: ${entry.item}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return settings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Could not load settings: $error')),
      data: (settings) {
        final view = MarketplaceView.from(settings, _price.text);
        final item = _ItemCard(
          view: view,
          item: _item,
          price: _price,
          onSave: view.canSave ? () => _save(view) : null,
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= wideLayoutWidth) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: SingleChildScrollView(child: item)),
                    const SizedBox(width: 24),
                    const Expanded(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: _Journal(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(child: item),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: _Journal.sliver(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.view,
    required this.item,
    required this.price,
    required this.onSave,
  });

  final MarketplaceView view;
  final TextEditingController item;
  final TextEditingController price;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final value = view.value;
    final official = value != null && value.validOfficial;
    String show(String Function() text) =>
        value == null ? '--' : (official ? text() : 'Needs valid Quna rates');
    return SectionCard(
      title: 'Marketplace item',
      children: [
        TextField(
          key: const Key('marketItem'),
          controller: item,
          maxLength: JournalRepository.maxItemLength,
          decoration: const InputDecoration(
            labelText: 'Item name',
            counterText: '',
          ),
        ),
        TextField(
          key: const Key('marketPrice'),
          controller: price,
          decoration: InputDecoration(
            labelText: 'Price in Kina',
            helperText: 'Such as 25m, 750k or 25000000',
            errorText: view.error,
          ),
        ),
        const Divider(),
        ResultRow(
          key: const Key('marketQuna'),
          label: 'Quna equivalent',
          value: show(() => formatQuna(value!.qunaExact)),
        ),
        ResultRow(
          key: const Key('marketOfficial'),
          label: 'Official value',
          value: show(() => view.money(value!.officialExact)),
          emphasize: true,
        ),
        ResultRow(
          key: const Key('marketChests'),
          label: 'Whole chests',
          value: show(
            () =>
                '${value!.chestCount} · '
                '${formatQuna(value.qunaWholeChests)}',
          ),
        ),
        ResultRow(
          key: const Key('marketWhole'),
          label: 'Official value, whole chests',
          value: show(() => view.money(value!.officialWholeChests)),
        ),
        ResultRow(
          key: const Key('marketRmt'),
          label: 'RMT value',
          value: value == null ? '--' : view.money(value.rmt.total),
          emphasize: true,
        ),
        Text(view.differenceLine, key: const Key('marketDifference')),
        Text(
          'Uses the rates, fees and RMT price from the calculator · '
          'estimates, not a checkout quote',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            key: const Key('saveItem'),
            onPressed: onSave,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Save to journal'),
          ),
        ),
      ],
    );
  }
}

/// The journal header, totals and entries.
class _Journal extends ConsumerWidget {
  const _Journal() : _sliver = false;

  const _Journal.sliver() : _sliver = true;

  final bool _sliver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalProvider).value ?? const [];
    final header = _JournalHeader(entries: entries);
    Widget row(int i) => _JournalRow(entry: entries[i]);
    if (_sliver) {
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(child: header),
          SliverList.builder(
            itemCount: entries.length,
            itemBuilder: (context, i) => row(i),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, i) => row(i),
          ),
        ),
      ],
    );
  }
}

class _JournalHeader extends ConsumerWidget {
  const _JournalHeader({required this.entries});

  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final official = entries.fold(Decimal.zero, (s, e) => s + e.officialEur);
    final rmt = entries.fold(Decimal.zero, (s, e) => s + e.rmtEur);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Purchase journal',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              OutlinedButton.icon(
                key: const Key('exportJournal'),
                onPressed: entries.isEmpty
                    ? null
                    : () => exportCsv(
                        context,
                        ref,
                        stem: 'kina_journal',
                        csv: journalCsv(entries),
                      ),
                icon: const Icon(Icons.download),
                label: const Text('Export CSV'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            entries.isEmpty
                ? 'No saved items yet'
                : '${entries.length} items · '
                      '${formatMoney(official, 'EUR')} official · '
                      '${formatMoney(rmt, 'EUR')} RMT',
            key: const Key('journalTotals'),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _JournalRow extends ConsumerWidget {
  const _JournalRow({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(entry.item, overflow: TextOverflow.ellipsis),
    subtitle: Text(
      '${formatDateTime(entry.date)} · ${formatKina(entry.kina)}\n'
      '${formatMoney(entry.officialEur, 'EUR')} official · '
      '${formatMoney(entry.rmtEur, 'EUR')} RMT',
    ),
    isThreeLine: true,
    trailing: IconButton(
      key: Key('deleteEntry-${entry.id}'),
      tooltip: 'Delete',
      icon: const Icon(Icons.delete_outline),
      onPressed: () async {
        final ok = await confirmDelete(
          context,
          title: 'Delete this entry?',
          message: 'The saved entry for ${entry.item} will be removed.',
        );
        if (ok) {
          await ref.read(journalProvider.notifier).delete(entry);
        }
      },
    ),
  );
}
