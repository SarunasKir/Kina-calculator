import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kina_app/src/analysis/analysis_logic.dart';
import 'package:kina_app/src/analysis/history_chart.dart';
import 'package:kina_app/src/export/csv.dart';
import 'package:kina_app/src/export/export_action.dart';
import 'package:kina_app/src/format.dart';
import 'package:kina_app/src/providers.dart';
import 'package:kina_app/src/widgets/confirm.dart';
import 'package:kina_app/src/widgets/section_card.dart';
import 'package:kina_data/kina_data.dart';
import 'package:uuid/uuid.dart';

/// Price breakdown, saved profiles and price history.
class AnalysisScreen extends StatelessWidget {
  /// Creates the screen.
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) => const DefaultTabController(
    length: 3,
    child: Column(
      children: [
        TabBar(
          tabs: [
            Tab(key: Key('breakdownTab'), text: 'Breakdown'),
            Tab(key: Key('profilesTab'), text: 'Profiles'),
            Tab(key: Key('historyTab'), text: 'History'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [_BreakdownTab(), _ProfilesTab(), _HistoryTab()],
          ),
        ),
      ],
    ),
  );
}

/// Centers the children at a readable width and lets it scroll.
class _Page extends StatelessWidget {
  const _Page({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 860),
      child: ListView(padding: const EdgeInsets.all(16), children: children),
    ),
  );
}

class _BreakdownTab extends ConsumerWidget {
  const _BreakdownTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(calculatorViewProvider).value;
    if (view == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final theme = Theme.of(context);
    return _Page(
      children: [
        SectionCard(
          title: 'How the total is built',
          children: [
            for (final line in breakdown(view))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.label, style: theme.textTheme.labelLarge),
                  Text(line.value, style: theme.textTheme.bodyLarge),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _ProfilesTab extends ConsumerStatefulWidget {
  const _ProfilesTab();

  @override
  ConsumerState<_ProfilesTab> createState() => _ProfilesTabState();
}

class _ProfilesTabState extends ConsumerState<_ProfilesTab> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _save() async {
    try {
      final profile = await ref
          .read(profilesProvider.notifier)
          .saveCurrent(_name.text);
      _notice('Saved profile: ${profile.name}');
    } on ProfileException catch (e) {
      _notice(switch (e.error) {
        ProfileError.emptyName => 'Enter a profile name first',
        ProfileError.nameTooLong =>
          'Profile names can be at most '
              '${ProfileRepository.maxNameLength} characters',
        ProfileError.tooMany =>
          'You can keep ${ProfileRepository.maxProfiles} profiles. '
              'Delete an old one first',
      });
    }
  }

  Future<void> _load(Profile profile) async {
    await ref.read(profilesProvider.notifier).load(profile);
    _notice('Loaded ${profile.name} into the calculator');
  }

  Future<void> _delete(Profile profile) async {
    final ok = await confirmDelete(
      context,
      title: 'Delete this profile?',
      message: 'The profile ${profile.name} will be removed.',
    );
    if (ok) {
      await ref.read(profilesProvider.notifier).delete(profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider).value ?? const [];
    return _Page(
      children: [
        SectionCard(
          title: 'Save the calculator as a profile',
          children: [
            TextField(
              key: const Key('profileName'),
              controller: _name,
              maxLength: ProfileRepository.maxNameLength,
              decoration: const InputDecoration(
                labelText: 'Profile name',
                helperText: 'Saving an existing name updates that profile',
              ),
              onSubmitted: (_) => _save(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const Key('saveProfile'),
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save profile'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title:
              'Saved profiles (${profiles.length} of '
              '${ProfileRepository.maxProfiles})',
          children: [
            if (profiles.isEmpty) const Text('No profiles saved yet'),
            for (final p in profiles)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(p.name),
                subtitle: Text('Updated ${formatDateTime(p.updatedAt)}'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                      key: Key('loadProfile-${p.name}'),
                      onPressed: () => _load(p),
                      child: const Text('Load'),
                    ),
                    IconButton(
                      key: Key('deleteProfile-${p.name}'),
                      tooltip: 'Delete',
                      onPressed: () => _delete(p),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HistoryTab extends ConsumerStatefulWidget {
  const _HistoryTab();

  @override
  ConsumerState<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<_HistoryTab> {
  HistorySeries _series = const HistorySeries.seller(0, 'Seller A');

  Future<void> _record() async {
    final view = ref.read(calculatorViewProvider).value;
    if (view == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      final snapshot = snapshotOf(
        view,
        id: const Uuid().v4(),
        takenAt: clock.now(),
      );
      await ref.read(snapshotsProvider.notifier).add(snapshot);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Snapshot saved: ${formatDateTime(snapshot.takenAt)}'),
        ),
      );
    } on SnapshotException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshots = ref.watch(snapshotsProvider).value ?? const [];
    final series = seriesOf(snapshots);
    final selected = series.contains(_series) ? _series : series.first;
    final points = pointsOf(snapshots, selected);
    final theme = Theme.of(context);
    return _Page(
      children: [
        SectionCard(
          title: 'Price history',
          children: [
            Text(
              snapshots.isEmpty
                  ? 'No snapshots yet. Save one to start tracking prices.'
                  : '${snapshots.length} snapshots · latest '
                        '${formatDateTime(snapshots.last.takenAt)}',
              key: const Key('historyStatus'),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  key: const Key('saveSnapshot'),
                  onPressed: _record,
                  icon: const Icon(Icons.add_chart),
                  label: const Text('Save price snapshot'),
                ),
                OutlinedButton.icon(
                  key: const Key('exportHistory'),
                  onPressed: snapshots.isEmpty
                      ? null
                      : () => exportCsv(
                          context,
                          ref,
                          stem: 'kina_price_history',
                          csv: snapshotsCsv(snapshots),
                        ),
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                ),
              ],
            ),
            DropdownButtonFormField<HistorySeries>(
              key: const Key('series'),
              initialValue: selected,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Show'),
              items: [
                for (final s in series)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: (s) => setState(() => _series = s!),
            ),
            Text(
              'All-in EUR per 1M Kina · rates converted to EUR when saved · '
              'latest $chartWindow snapshots',
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: 260, child: HistoryChart(points: points)),
          ],
        ),
      ],
    );
  }
}
