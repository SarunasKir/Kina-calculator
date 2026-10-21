import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:kina_data/src/database.dart';
import 'package:kina_data/src/models.dart';

/// Stores price snapshots (requirement FR-18).
class SnapshotRepository {
  /// Creates the repository on a database.
  SnapshotRepository(this._db);

  /// Most snapshots kept; older ones are deleted.
  static const maxSnapshots = 500;

  final KinaDatabase _db;

  static PriceSnapshot _toSnapshot(SnapshotRow row) => PriceSnapshot(
    id: row.id,
    takenAt: row.takenAt,
    currency: row.currency,
    eurRate: row.eurRate,
    rateSource: row.rateSource,
    rateDate: row.rateDate,
    millions: row.millions,
    sellers: [
      for (final s in jsonDecode(row.sellersJson) as List<Object?>)
        SnapshotPrice.fromJson(s! as Map<String, Object?>),
    ],
    officialEurPerMillion: row.officialEurPerMillion,
  );

  /// Snapshots oldest first. With [latest], only the newest that many.
  Future<List<PriceSnapshot>> list({int? latest}) async {
    final query = _db.select(_db.snapshots)
      ..where((t) => t.deleted.not())
      ..orderBy([(t) => OrderingTerm.desc(t.takenAt)]);
    if (latest != null) {
      query.limit(latest);
    }
    final rows = await query.get();
    return rows.reversed.map(_toSnapshot).toList();
  }

  /// Saves [snapshot] and deletes the oldest beyond [maxSnapshots].
  Future<void> add(PriceSnapshot snapshot) => _db.transaction(() async {
    final now = clock.now();
    await _db
        .into(_db.snapshots)
        .insertOnConflictUpdate(
          SnapshotRow(
            id: snapshot.id,
            updatedAt: now,
            deleted: false,
            takenAt: snapshot.takenAt,
            currency: snapshot.currency,
            eurRate: snapshot.eurRate,
            rateSource: snapshot.rateSource,
            rateDate: snapshot.rateDate,
            millions: snapshot.millions,
            sellersJson: jsonEncode([
              for (final s in snapshot.sellers) s.toJson(),
            ]),
            officialEurPerMillion: snapshot.officialEurPerMillion,
          ),
        );
    final overflow =
        await (_db.select(_db.snapshots)
              ..where((t) => t.deleted.not())
              ..orderBy([(t) => OrderingTerm.desc(t.takenAt)])
              ..limit(-1, offset: maxSnapshots))
            .get();
    if (overflow.isNotEmpty) {
      await (_db.update(
        _db.snapshots,
      )..where((t) => t.id.isIn(overflow.map((r) => r.id)))).write(
        SnapshotsCompanion(deleted: const Value(true), updatedAt: Value(now)),
      );
    }
  });
}
