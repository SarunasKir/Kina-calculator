import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kina_app/src/calculator/calculator_logic.dart';
import 'package:kina_app/src/calculator/calculator_view.dart';
import 'package:kina_app/src/files/file_access.dart';
import 'package:kina_app/src/rates/rate_sync.dart';
import 'package:kina_app/src/sources/price_extractor.dart';
import 'package:kina_app/src/sources/seller_prices.dart';
import 'package:kina_app/src/sources/source_client.dart';
import 'package:kina_data/kina_data.dart';
import 'package:url_launcher/url_launcher.dart';

/// The open database. `main` overrides this with the real one.
final databaseProvider = Provider<KinaDatabase>(
  (ref) => throw UnimplementedError('Override databaseProvider in main'),
);

/// The rate client. Tests override this with a fake.
final rateClientProvider = Provider<FrankfurterClient>(
  (ref) => FrankfurterClient(),
);

/// Downloads seller pages. Tests override this with a fake.
final sourceClientProvider = Provider<SourceClient>((ref) => SourceClient());

/// Saving and opening files. Tests override this with a fake.
final fileAccessProvider = Provider<FileAccess>(
  (ref) => const PlatformFileAccess(),
);

/// Opens a web link in the browser. Tests override this with a fake.
final linkOpenerProvider = Provider<Future<bool> Function(Uri)>(
  (ref) => launchUrl,
);

/// Settings storage.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

/// Profile storage.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(databaseProvider)),
);

/// Snapshot storage.
final snapshotRepositoryProvider = Provider<SnapshotRepository>(
  (ref) => SnapshotRepository(ref.watch(databaseProvider)),
);

/// Journal storage.
final journalRepositoryProvider = Provider<JournalRepository>(
  (ref) => JournalRepository(ref.watch(databaseProvider)),
);

/// The live calculator settings. Every change is saved straight away.
final settingsProvider =
    AsyncNotifierProvider<SettingsController, CalculatorSettings>(
      SettingsController.new,
    );

/// What the calculator screen shows.
final calculatorViewProvider = Provider<AsyncValue<CalculatorView>>(
  (ref) => ref.watch(settingsProvider).whenData(CalculatorView.from),
);

/// Holds the settings and saves each change.
class SettingsController extends AsyncNotifier<CalculatorSettings> {
  @override
  Future<CalculatorSettings> build() =>
      ref.watch(settingsRepositoryProvider).load();

  /// Applies [change] to the current settings and saves the result.
  Future<void> edit(
    CalculatorSettings Function(CalculatorSettings current) change,
  ) async {
    final current = state.value;
    if (current == null) {
      return;
    }
    final next = change(current);
    state = AsyncData(next);
    await ref.read(settingsRepositoryProvider).save(next);
  }

  /// Restores the v55 defaults (requirement FR-7).
  Future<void> reset() => edit((_) => CalculatorSettings.defaults);

  /// Fetches ECB rates and applies them. Throws [RateSyncException] and
  /// leaves the settings unchanged on failure.
  Future<PublishedRates> syncRates() async {
    final published = await ref.read(rateClientProvider).latest();
    await edit(
      (s) => applySyncedRates(s, {
        ...s.ratesPerEur,
        ...published.perEur,
      }, published.date),
    );
    return published;
  }

  /// Fetches the price of each seller that has a site address (only seller
  /// [only] when given) and saves the ones that were read. Returns one
  /// message per seller that was tried: the new price or the reason it
  /// failed.
  Future<List<String>> fetchSellerPrices({int? only}) async {
    final current = state.value;
    if (current == null) {
      return const [];
    }
    final client = ref.read(sourceClientProvider);
    final tried = [
      for (var i = 0; i < current.sellers.length; i++)
        if ((only == null || only == i) &&
            (current.sellers[i].source?.url.trim().isNotEmpty ?? false))
          i,
    ];
    final prices = <int, String>{};
    final messages = await Future.wait([
      for (final i in tried)
        () async {
          final seller = current.sellers[i];
          try {
            prices[i] = await fetchSellerPrice(client, current, seller);
            return '${seller.name}: ${prices[i]}';
          } on SourceReadException catch (e) {
            return '${seller.name}: ${e.message}';
          }
        }(),
    ]);
    await edit(
      (s) => s.copyWith(
        sellers: [
          for (var i = 0; i < s.sellers.length; i++)
            s.sellers[i].copyWith(
              pricePerMillion: prices[i] ?? s.sellers[i].pricePerMillion,
            ),
        ],
      ),
    );
    return messages;
  }
}

/// Saved profiles, sorted by name (requirement FR-17).
final profilesProvider =
    AsyncNotifierProvider<ProfilesController, List<Profile>>(
      ProfilesController.new,
    );

/// Lists, saves and deletes profiles.
class ProfilesController extends AsyncNotifier<List<Profile>> {
  @override
  Future<List<Profile>> build() => ref.watch(profileRepositoryProvider).list();

  /// Saves the current calculator settings as [name]. Throws
  /// [ProfileException] when the name or count is not allowed.
  Future<Profile> saveCurrent(String name) async {
    final settings = await ref.read(settingsProvider.future);
    final profile = await ref
        .read(profileRepositoryProvider)
        .save(name, settings);
    ref.invalidateSelf();
    return profile;
  }

  /// Puts [profile]'s settings into the calculator.
  Future<void> load(Profile profile) =>
      ref.read(settingsProvider.notifier).edit((_) => profile.settings);

  /// Deletes [profile].
  Future<void> delete(Profile profile) async {
    await ref.read(profileRepositoryProvider).delete(profile.id);
    ref.invalidateSelf();
  }
}

/// Saved price snapshots, oldest first (requirement FR-18).
final snapshotsProvider =
    AsyncNotifierProvider<SnapshotsController, List<PriceSnapshot>>(
      SnapshotsController.new,
    );

/// Lists and adds snapshots.
class SnapshotsController extends AsyncNotifier<List<PriceSnapshot>> {
  @override
  Future<List<PriceSnapshot>> build() =>
      ref.watch(snapshotRepositoryProvider).list();

  /// Saves [snapshot].
  Future<void> add(PriceSnapshot snapshot) async {
    await ref.read(snapshotRepositoryProvider).add(snapshot);
    ref.invalidateSelf();
  }
}

/// The marketplace purchase journal, newest first (requirement FR-14).
final journalProvider =
    AsyncNotifierProvider<JournalController, List<JournalEntry>>(
      JournalController.new,
    );

/// Lists, adds and deletes journal entries.
class JournalController extends AsyncNotifier<List<JournalEntry>> {
  @override
  Future<List<JournalEntry>> build() =>
      ref.watch(journalRepositoryProvider).list();

  /// Saves [entry].
  Future<void> add(JournalEntry entry) async {
    await ref.read(journalRepositoryProvider).add(entry);
    ref.invalidateSelf();
  }

  /// Deletes [entry].
  Future<void> delete(JournalEntry entry) async {
    await ref.read(journalRepositoryProvider).delete(entry.id);
    ref.invalidateSelf();
  }
}
