import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kina_app/src/format.dart';
import 'package:kina_app/src/sync/sync_providers.dart';
import 'package:kina_app/src/widgets/confirm.dart';
import 'package:kina_app/src/widgets/section_card.dart';
import 'package:kina_sync/kina_sync.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Sync between the PC and phones: on the PC it runs the hub and pairs
/// phones, on a phone it pairs with the PC and syncs.
class SyncCard extends ConsumerWidget {
  /// Creates the card.
  const SyncCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(syncRoleProvider) == SyncRole.hub
      ? const _HubCard()
      : const _PhoneCard();
}

class _HubCard extends ConsumerWidget {
  const _HubCard();

  Future<void> _addPhone(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(hubControllerProvider.notifier);
    final offer = await controller.createOffer();
    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => _OfferDialog(offer: offer),
    );
    await controller.reload();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(hubControllerProvider);
    final controller = ref.read(hubControllerProvider.notifier);
    return SectionCard(
      title: 'Sync with your phone',
      children: [
        const Text(
          'Your phone syncs with this PC over your home Wi-Fi. Nothing '
          'goes through the internet. Keep this app open while syncing; '
          'Windows may ask to allow it through the firewall the first time.',
        ),
        hub.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Sync is unavailable: $e'),
          data: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                key: const Key('hubSwitch'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Let phones sync with this PC'),
                value: state.running,
                onChanged: (on) => controller.setRunning(running: on),
              ),
              if (state.running)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    key: const Key('addPhone'),
                    onPressed: () => _addPhone(context, ref),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Add a phone'),
                  ),
                ),
              for (final d in state.devices)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.smartphone),
                  title: Text(d.name),
                  subtitle: Text(
                    d.lastSyncAt == null
                        ? 'Paired, not synced yet'
                        : 'Last synced ${formatDateTime(d.lastSyncAt!)}',
                  ),
                  trailing: IconButton(
                    key: Key('removeDevice-${d.id}'),
                    tooltip: 'Remove',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await confirmDelete(
                        context,
                        title: 'Remove this phone?',
                        message:
                            '${d.name} will stop syncing until you pair it '
                            'again. Its data stays on the phone.',
                      );
                      if (ok) {
                        await controller.remove(d);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OfferDialog extends StatelessWidget {
  const _OfferDialog({required this.offer});

  final PairingOffer offer;

  @override
  // A plain Dialog, because the QR code's layout builder cannot sit inside an
  // AlertDialog's intrinsic sizing.
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add a phone', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              'On the phone, open Kina Calculator, go to More and paste this '
              'pairing code. The code works once and expires in '
              '${offerLifetime.inMinutes} minutes.',
            ),
            const SizedBox(height: 16),
            Center(
              child: QrImageView(
                key: const Key('pairingQr'),
                data: offer.code,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              offer.code,
              key: const Key('pairingCode'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton.icon(
                  key: const Key('copyCode'),
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: offer.code)),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy code'),
                ),
                FilledButton(
                  key: const Key('closeOffer'),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _PhoneCard extends ConsumerStatefulWidget {
  const _PhoneCard();

  @override
  ConsumerState<_PhoneCard> createState() => _PhoneCardState();
}

class _PhoneCardState extends ConsumerState<_PhoneCard> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      messenger.showSnackBar(SnackBar(content: Text(await action())));
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on SyncException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _pair() => _run(() async {
    final controller = ref.read(pairingProvider.notifier);
    await controller.pair(_code.text);
    _code.clear();
    final report = await controller.syncNow();
    return 'Paired and synced: ${_describe(report)}';
  });

  Future<void> _sync() => _run(() async {
    final report = await ref.read(pairingProvider.notifier).syncNow();
    return 'Synced: ${_describe(report)}';
  });

  static String _describe(SyncReport r) =>
      '${r.sent} sent, ${r.applied} updated here';

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _code.text = data!.text!.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pairing = ref.watch(pairingProvider).value;
    return SectionCard(
      title: 'Sync with your PC',
      children: [
        if (pairing == null) ...[
          const Text(
            'On the PC, open Kina Calculator, go to More, switch on sync and '
            'choose Add a phone. Then paste the pairing code here. Both '
            'devices must be on the same Wi-Fi.',
          ),
          TextField(
            key: const Key('pairingInput'),
            controller: _code,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Pairing code',
              suffixIcon: IconButton(
                key: const Key('pasteCode'),
                tooltip: 'Paste',
                icon: const Icon(Icons.paste),
                onPressed: _paste,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const Key('pair'),
              onPressed: _busy ? null : _pair,
              icon: const Icon(Icons.link),
              label: Text(_busy ? 'Pairing…' : 'Pair with PC'),
            ),
          ),
        ] else ...[
          Text(
            'Paired with a PC at ${pairing.addresses.first}. '
            'Your data syncs when both are on the same Wi-Fi.',
            key: const Key('pairedText'),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                key: const Key('syncNow'),
                onPressed: _busy ? null : _sync,
                icon: const Icon(Icons.sync),
                label: Text(_busy ? 'Syncing…' : 'Sync now'),
              ),
              OutlinedButton.icon(
                key: const Key('unpair'),
                onPressed: () async {
                  final ok = await confirmDelete(
                    context,
                    title: 'Unpair from the PC?',
                    message: 'Syncing stops. The data on this phone stays.',
                  );
                  if (ok) {
                    await ref.read(pairingProvider.notifier).unpair();
                  }
                },
                icon: const Icon(Icons.link_off),
                label: const Text('Unpair'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
