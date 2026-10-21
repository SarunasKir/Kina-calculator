import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kina_app/src/calculator/calculator_logic.dart';
import 'package:kina_app/src/calculator/calculator_view.dart';
import 'package:kina_app/src/rates/rate_sync.dart';
import 'package:kina_data/kina_data.dart';

/// The open database. `main` overrides this with the real one.
final databaseProvider = Provider<KinaDatabase>(
  (ref) => throw UnimplementedError('Override databaseProvider in main'),
);

/// The rate client. Tests override this with a fake.
final rateClientProvider = Provider<FrankfurterClient>(
  (ref) => FrankfurterClient(),
);

/// Settings storage.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
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
    final current = state.value;
    final codes = current?.ratesPerEur.keys.toList() ?? const <String>[];
    final published = await ref.read(rateClientProvider).latest(codes);
    await edit((s) => applySyncedRates(s, published.perEur, published.date));
    return published;
  }
}
