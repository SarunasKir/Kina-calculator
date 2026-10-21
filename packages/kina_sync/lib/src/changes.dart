import 'package:drift/drift.dart';
import 'package:kina_data/kina_data.dart';
import 'package:meta/meta.dart';

/// The tables that sync, by SQL name. Device-only values never do.
const syncedTables = ['settings', 'profiles', 'snapshots', 'journal_entries'];

/// Records changed on a device, grouped by table. Each record is the row as
/// stored: column name to JSON-safe value.
@immutable
class ChangeSet {
  /// Creates a change set.
  const ChangeSet(this.tables);

  /// Reads a change set from JSON.
  factory ChangeSet.fromJson(Map<String, Object?> json) => ChangeSet({
    for (final e in json.entries)
      if (syncedTables.contains(e.key))
        e.key: [
          for (final r in e.value! as List<Object?>)
            Map<String, Object?>.from(r! as Map<String, Object?>),
        ],
  });

  /// No changes.
  static const empty = ChangeSet({});

  /// Records by table name.
  final Map<String, List<Map<String, Object?>>> tables;

  /// Number of records.
  int get length => tables.values.fold(0, (sum, rows) => sum + rows.length);

  /// Converts to JSON.
  Map<String, Object?> toJson() => tables;
}

/// What applying a change set did.
@immutable
class ApplyResult {
  /// Creates a result.
  const ApplyResult({required this.applied, required this.skipped});

  /// Records that were newer than ours and were stored.
  final int applied;

  /// Records that were older or equal and were ignored.
  final int skipped;
}

DateTime _time(Object? value) => DateTime.parse(value! as String).toUtc();

/// Reads every record in the synced tables that changed after [since]
/// (everything when null).
Future<ChangeSet> exportChanges(KinaDatabase db, {DateTime? since}) async {
  final tables = <String, List<Map<String, Object?>>>{};
  for (final table in syncedTables) {
    final rows = await db.customSelect('SELECT * FROM $table').get();
    final changed = [
      for (final row in rows)
        if (since == null || _time(row.data['updated_at']).isAfter(since))
          Map<String, Object?>.from(row.data),
    ];
    if (changed.isNotEmpty) {
      tables[table] = changed;
    }
  }
  return ChangeSet(tables);
}

/// Stores the records of [changes] that are newer than ours: the newest
/// version of each record wins (last write wins by `updated_at`). Unknown
/// tables and columns are rejected.
///
/// Throws [FormatException] for a record that does not fit the database.
Future<ApplyResult> applyChanges(KinaDatabase db, ChangeSet changes) =>
    db.transaction(() async {
      var applied = 0;
      var skipped = 0;
      for (final MapEntry(key: table, value: rows) in changes.tables.entries) {
        if (!syncedTables.contains(table)) {
          throw FormatException('Unknown table $table');
        }
        final columns = {
          for (final c
              in await db.customSelect('PRAGMA table_info($table)').get())
            c.read<String>('name'),
        };
        for (final row in rows) {
          if (!row.keys.every(columns.contains) ||
              !columns.every(row.containsKey)) {
            throw FormatException('Record does not match table $table');
          }
          final id = row['id'];
          final updated = row['updated_at'];
          if (id is! String || updated is! String) {
            throw FormatException('Record in $table has no id or time');
          }
          final existing = await db
              .customSelect(
                'SELECT updated_at FROM $table WHERE id = ?',
                variables: [Variable<String>(id)],
              )
              .getSingleOrNull();
          if (existing != null &&
              !_time(updated).isAfter(_time(existing.data['updated_at']))) {
            skipped++;
            continue;
          }
          final names = row.keys.toList();
          await db.customStatement(
            'INSERT OR REPLACE INTO $table (${names.join(', ')}) '
            'VALUES (${List.filled(names.length, '?').join(', ')})',
            [for (final n in names) row[n]],
          );
          applied++;
        }
      }
      return ApplyResult(applied: applied, skipped: skipped);
    });
