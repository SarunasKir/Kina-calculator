import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:kina_data/src/database.dart';
import 'package:kina_data/src/models.dart';
import 'package:uuid/uuid.dart';

/// Why a profile could not be saved.
enum ProfileError {
  /// The name is empty.
  emptyName,

  /// The name is longer than [ProfileRepository.maxNameLength].
  nameTooLong,

  /// There are already [ProfileRepository.maxProfiles] profiles.
  tooMany,
}

/// Thrown when a profile cannot be saved.
class ProfileException implements Exception {
  /// Creates the exception.
  const ProfileException(this.error);

  /// What went wrong.
  final ProfileError error;

  @override
  String toString() => 'ProfileException: ${error.name}';
}

/// Saves, loads and deletes named profiles (requirement FR-17).
class ProfileRepository {
  /// Creates the repository on a database.
  ProfileRepository(this._db, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  /// Most profiles kept, as in v55.
  static const maxProfiles = 50;

  /// Longest profile name, as in v55.
  static const maxNameLength = 42;

  final KinaDatabase _db;
  final Uuid _uuid;

  static Profile _toProfile(ProfileRow row) => Profile(
    id: row.id,
    name: row.name,
    updatedAt: row.updatedAt,
    settings: CalculatorSettings.fromJson(
      jsonDecode(row.settingsJson) as Map<String, Object?>,
    ),
  );

  SimpleSelectStatement<$ProfilesTable, ProfileRow> get _live =>
      _db.select(_db.profiles)..where((t) => t.deleted.not());

  /// All profiles, sorted by name ignoring case.
  Future<List<Profile>> list() async {
    final rows = await _live.get();
    return rows.map(_toProfile).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Saves [settings] under [name]. A profile with the same name, ignoring
  /// case, is updated; otherwise a new one is created.
  ///
  /// Throws [ProfileException] for an empty or long name, or when the limit
  /// is reached.
  Future<Profile> save(String name, CalculatorSettings settings) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ProfileException(ProfileError.emptyName);
    }
    if (trimmed.runes.length > maxNameLength) {
      throw const ProfileException(ProfileError.nameTooLong);
    }
    return await _db.transaction(() async {
      final rows = await _live.get();
      final existing = rows
          .where((r) => r.name.toLowerCase() == trimmed.toLowerCase())
          .firstOrNull;
      if (existing == null && rows.length >= maxProfiles) {
        throw const ProfileException(ProfileError.tooMany);
      }
      final row = ProfileRow(
        id: existing?.id ?? _uuid.v4(),
        name: trimmed,
        updatedAt: clock.now(),
        deleted: false,
        settingsJson: jsonEncode(settings.toJson()),
      );
      await _db.into(_db.profiles).insertOnConflictUpdate(row);
      return _toProfile(row);
    });
  }

  /// Deletes the profile with [id].
  Future<void> delete(String id) =>
      (_db.update(_db.profiles)..where((t) => t.id.equals(id))).write(
        ProfilesCompanion(
          deleted: const Value(true),
          updatedAt: Value(clock.now()),
        ),
      );
}
