import 'package:clock/clock.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:kina_data/src/database.dart';
import 'package:kina_data/src/models.dart';
import 'package:meta/meta.dart';

/// Sums of the saved valuations, in EUR.
@immutable
class JournalTotals {
  /// Creates totals.
  const JournalTotals({
    required this.count,
    required this.officialEur,
    required this.rmtEur,
  });

  /// Number of entries.
  final int count;

  /// Sum of official values.
  final Decimal officialEur;

  /// Sum of RMT values.
  final Decimal rmtEur;
}

/// Stores the marketplace purchase journal (requirements FR-14, FR-15).
class JournalRepository {
  /// Creates the repository on a database.
  JournalRepository(this._db);

  /// Most entries kept; older ones are deleted.
  static const maxEntries = 3000;

  /// Longest item name kept.
  static const maxItemLength = 80;

  /// Name used when the item name is blank.
  static const unnamedItem = 'Unnamed marketplace item';

  final KinaDatabase _db;

  static JournalEntry _toEntry(JournalRow row) => JournalEntry(
    id: row.id,
    date: row.date,
    item: row.item,
    kina: row.kina,
    qunaEquivalent: row.qunaEquivalent,
    officialEur: row.officialEur,
    rmtEur: row.rmtEur,
    currency: row.currency,
    fxRatePerEur: row.fxRatePerEur,
  );

  /// Cleans an item name: trims it, cuts it to [maxItemLength] characters and
  /// uses [unnamedItem] when blank.
  static String cleanItemName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return unnamedItem;
    }
    final runes = trimmed.runes;
    return runes.length <= maxItemLength
        ? trimmed
        : String.fromCharCodes(runes.take(maxItemLength));
  }

  /// Entries newest first.
  Future<List<JournalEntry>> list() async {
    final rows =
        await (_db.select(_db.journalEntries)
              ..where((t) => t.deleted.not())
              ..orderBy([(t) => OrderingTerm.desc(t.date)]))
            .get();
    return rows.map(_toEntry).toList();
  }

  /// Totals over all entries.
  Future<JournalTotals> totals() async {
    final entries = await list();
    return JournalTotals(
      count: entries.length,
      officialEur: entries.fold(Decimal.zero, (sum, e) => sum + e.officialEur),
      rmtEur: entries.fold(Decimal.zero, (sum, e) => sum + e.rmtEur),
    );
  }

  /// Saves [entry] with a cleaned name and deletes the oldest beyond
  /// [maxEntries].
  Future<void> add(JournalEntry entry) => _db.transaction(() async {
    final now = clock.now();
    await _db
        .into(_db.journalEntries)
        .insertOnConflictUpdate(
          JournalRow(
            id: entry.id,
            updatedAt: now,
            deleted: false,
            date: entry.date,
            item: cleanItemName(entry.item),
            kina: entry.kina,
            qunaEquivalent: entry.qunaEquivalent,
            officialEur: entry.officialEur,
            rmtEur: entry.rmtEur,
            currency: entry.currency,
            fxRatePerEur: entry.fxRatePerEur,
          ),
        );
    final overflow =
        await (_db.select(_db.journalEntries)
              ..where((t) => t.deleted.not())
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(-1, offset: maxEntries))
            .get();
    if (overflow.isNotEmpty) {
      await (_db.update(
        _db.journalEntries,
      )..where((t) => t.id.isIn(overflow.map((r) => r.id)))).write(
        JournalEntriesCompanion(
          deleted: const Value(true),
          updatedAt: Value(now),
        ),
      );
    }
  });

  /// Deletes the entry with [id].
  Future<void> delete(String id) =>
      (_db.update(_db.journalEntries)..where((t) => t.id.equals(id))).write(
        JournalEntriesCompanion(
          deleted: const Value(true),
          updatedAt: Value(clock.now()),
        ),
      );
}
