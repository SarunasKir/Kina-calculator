import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kina_app/src/files/file_access.dart';
import 'package:kina_app/src/help/help.dart';
import 'package:kina_app/src/providers.dart';
import 'package:kina_app/src/sync/sync_card.dart';
import 'package:kina_app/src/widgets/section_card.dart';
import 'package:kina_data/kina_data.dart';

/// Runs [importV55] on the v55 files among [files], matched by file name.
/// Returns null if none of the files is a v55 data file.
Future<ImportSummary?> importV55Files(KinaDatabase db, List<PickedFile> files) {
  String? find(String name) => files
      .where((f) => f.name.toLowerCase() == name)
      .map((f) => f.content)
      .firstOrNull;
  final settings = find('settings.json');
  final profiles = find('profiles.json');
  final history = find('price_history.json');
  final journal = find('marketplace_purchases.json');
  if ([settings, profiles, history, journal].every((f) => f == null)) {
    return Future.value();
  }
  return importV55(
    db,
    settingsJson: settings,
    profilesJson: profiles,
    historyJson: history,
    journalJson: journal,
  );
}

/// What an import brought in, in words.
String describeImport(ImportSummary s) => [
  if (s.settings) 'calculator settings',
  '${s.profiles} profiles',
  '${s.snapshots} snapshots',
  '${s.journalEntries} journal entries',
].join(', ');

/// Help guides, import from v55, and about.
class MoreScreen extends ConsumerWidget {
  /// Creates the screen.
  const MoreScreen({super.key});

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final files = await ref.read(fileAccessProvider).pickJsonFiles();
    if (files.isEmpty) {
      return;
    }
    try {
      final summary = await importV55Files(ref.read(databaseProvider), files);
      if (summary == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'No v55 files found. Pick settings.json, profiles.json, '
              'price_history.json or marketplace_purchases.json',
            ),
          ),
        );
        return;
      }
      ref
        ..invalidate(settingsProvider)
        ..invalidate(profilesProvider)
        ..invalidate(snapshotsProvider)
        ..invalidate(journalProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('Imported ${describeImport(summary)}')),
      );
    } on FormatException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Import failed: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    Widget guide(HelpTopic topic, IconData icon) => ListTile(
      key: Key('help-${topic.name}'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(topic.title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showHelp(context, topic),
    );
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SyncCard(),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Help',
              children: [
                guide(HelpTopic.vat, Icons.receipt_long_outlined),
                guide(HelpTopic.fees, Icons.credit_card),
                guide(HelpTopic.risks, Icons.warning_amber_outlined),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Import from v55',
              children: [
                const Text(
                  'Bring in your data from the old Windows app. Pick any of '
                  'settings.json, profiles.json, price_history.json and '
                  'marketplace_purchases.json from its data folder. '
                  'Importing the same files twice does not duplicate '
                  'history or journal entries.',
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    key: const Key('importV55'),
                    onPressed: () => _import(context, ref),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Choose files'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'About',
              children: [
                const Text(
                  'Kina Calculator compares buying Aion 2 Kina from RMT '
                  'sellers with the official Quna route. Calculations run '
                  'on this device and your data stays here. The app goes '
                  'online only when you sync exchange rates.',
                ),
                Text(
                  'Third-party trades carry risk. See Know the risks.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
