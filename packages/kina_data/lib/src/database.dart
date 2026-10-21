import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

part 'database.g.dart';

/// Stores [Decimal] values as exact text.
class DecimalConverter extends TypeConverter<Decimal, String> {
  /// Creates the converter.
  const DecimalConverter();

  @override
  Decimal fromSql(String fromDb) => Decimal.parse(fromDb);

  @override
  String toSql(Decimal value) => value.toString();
}

// Table definitions are read by the Drift code generator, not at runtime,
// so they are left out of coverage.
// coverage:ignore-start

/// Columns every synced table carries: a global id, the last change time and
/// a soft-delete flag, so deletions can be synced too.
mixin SyncColumns on Table {
  /// Globally unique record id.
  TextColumn get id => text()();

  /// When this record last changed, on any device.
  DateTimeColumn get updatedAt => dateTime()();

  /// Whether the record was deleted.
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The calculator settings, stored as one JSON document.
@DataClassName('SettingsRow')
class SettingsTable extends Table with SyncColumns {
  @override
  String get tableName => 'settings';

  /// `CalculatorSettings.toJson`, encoded.
  TextColumn get json => text()();
}

/// Named settings profiles.
@DataClassName('ProfileRow')
class Profiles extends Table with SyncColumns {
  /// Profile name.
  TextColumn get name => text()();

  /// `CalculatorSettings.toJson`, encoded.
  TextColumn get settingsJson => text()();
}

/// Saved price snapshots.
@DataClassName('SnapshotRow')
class Snapshots extends Table with SyncColumns {
  /// Capture time.
  DateTimeColumn get takenAt => dateTime()();

  /// Calculator currency at capture.
  TextColumn get currency => text()();

  /// Units of currency per 1 EUR at capture.
  TextColumn get eurRate => text().map(const DecimalConverter())();

  /// Rate source label.
  TextColumn get rateSource => text()();

  /// Rate publication date.
  TextColumn get rateDate => text().nullable()();

  /// Kina amount in millions.
  TextColumn get millions => text().map(const DecimalConverter())();

  /// Seller prices as a JSON list.
  TextColumn get sellersJson => text()();

  /// Official EUR per 1M, if valid.
  TextColumn get officialEurPerMillion =>
      text().nullable().map(const DecimalConverter())();
}

/// Saved marketplace item valuations.
@DataClassName('JournalRow')
class JournalEntries extends Table with SyncColumns {
  /// When saved.
  DateTimeColumn get date => dateTime()();

  /// Item name.
  TextColumn get item => text()();

  /// Price in raw Kina.
  TextColumn get kina => text().map(const DecimalConverter())();

  /// Proportional Quna value.
  TextColumn get qunaEquivalent => text().map(const DecimalConverter())();

  /// Official value in EUR.
  TextColumn get officialEur => text().map(const DecimalConverter())();

  /// RMT value in EUR.
  TextColumn get rmtEur => text().map(const DecimalConverter())();

  /// Calculator currency at capture.
  TextColumn get currency => text()();

  /// Units of currency per 1 EUR at capture.
  TextColumn get fxRatePerEur => text().map(const DecimalConverter())();
}

// coverage:ignore-end

/// The app's local SQLite database.
@DriftDatabase(tables: [SettingsTable, Profiles, Snapshots, JournalEntries])
class KinaDatabase extends _$KinaDatabase {
  /// Opens the database on [e]. Use `NativeDatabase.memory()` in tests
  /// and `drift_flutter` in the app.
  KinaDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
