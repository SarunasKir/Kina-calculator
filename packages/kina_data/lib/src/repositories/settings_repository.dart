import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:kina_data/src/database.dart';
import 'package:kina_data/src/models.dart';

/// Loads and saves the calculator settings.
class SettingsRepository {
  /// Creates the repository on a database.
  SettingsRepository(this._db);

  /// The settings record id; there is only ever one.
  static const recordId = 'settings';

  final KinaDatabase _db;

  SimpleSelectStatement<$SettingsTableTable, SettingsRow> get _query =>
      _db.select(_db.settingsTable)
        ..where((t) => t.id.equals(recordId) & t.deleted.not());

  static CalculatorSettings _decode(SettingsRow? row) => row == null
      ? CalculatorSettings.defaults
      : CalculatorSettings.fromJson(
          jsonDecode(row.json) as Map<String, Object?>,
        );

  /// The saved settings, or the v55 defaults when nothing is saved.
  Future<CalculatorSettings> load() async =>
      _decode(await _query.getSingleOrNull());

  /// Emits the settings now and after every change.
  Stream<CalculatorSettings> watch() => _query.watchSingleOrNull().map(_decode);

  /// Saves [settings], replacing what was there.
  Future<void> save(CalculatorSettings settings) => _db
      .into(_db.settingsTable)
      .insertOnConflictUpdate(
        SettingsTableCompanion.insert(
          id: recordId,
          updatedAt: clock.now(),
          json: jsonEncode(settings.toJson()),
          deleted: const Value(false),
        ),
      );

  /// Restores the v55 defaults (requirement FR-7).
  Future<void> reset() => save(CalculatorSettings.defaults);
}
