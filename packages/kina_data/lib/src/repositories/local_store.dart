import 'package:kina_data/src/database.dart';

/// Small named values that stay on this device and are never synced, such as
/// pairing keys.
class LocalStore {
  /// Creates the store on a database.
  LocalStore(this._db);

  final KinaDatabase _db;

  /// The value saved under [key], or null.
  Future<String?> read(String key) async {
    final row = await (_db.select(
      _db.localValues,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// Saves [value] under [key], replacing what was there.
  Future<void> write(String key, String value) => _db
      .into(_db.localValues)
      .insertOnConflictUpdate(
        LocalValuesCompanion.insert(key: key, value: value),
      );

  /// Removes [key].
  Future<void> remove(String key) =>
      (_db.delete(_db.localValues)..where((t) => t.key.equals(key))).go();
}
