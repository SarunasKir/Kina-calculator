// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, updatedAt, deleted, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  /// Globally unique record id.
  final String id;

  /// When this record last changed, on any device.
  final DateTime updatedAt;

  /// Whether the record was deleted.
  final bool deleted;

  /// `CalculatorSettings.toJson`, encoded.
  final String json;
  const SettingsRow({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.json,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['json'] = Variable<String>(json);
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      json: Value(json),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'json': serializer.toJson<String>(json),
    };
  }

  SettingsRow copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    String? json,
  }) => SettingsRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    json: json ?? this.json,
  );
  SettingsRow copyWithCompanion(SettingsTableCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, deleted, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.json == this.json);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<String> json;
  final Value<int> rowid;
  const SettingsTableCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    required String id,
    required DateTime updatedAt,
    this.deleted = const Value.absent(),
    required String json,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       json = Value(json);
  static Insertable<SettingsRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsTableCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return SettingsTableCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTable extends Profiles
    with TableInfo<$ProfilesTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settingsJsonMeta = const VerificationMeta(
    'settingsJson',
  );
  @override
  late final GeneratedColumn<String> settingsJson = GeneratedColumn<String>(
    'settings_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    name,
    settingsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('settings_json')) {
      context.handle(
        _settingsJsonMeta,
        settingsJson.isAcceptableOrUnknown(
          data['settings_json']!,
          _settingsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settingsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      settingsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settings_json'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  /// Globally unique record id.
  final String id;

  /// When this record last changed, on any device.
  final DateTime updatedAt;

  /// Whether the record was deleted.
  final bool deleted;

  /// Profile name.
  final String name;

  /// `CalculatorSettings.toJson`, encoded.
  final String settingsJson;
  const ProfileRow({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.name,
    required this.settingsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['name'] = Variable<String>(name);
    map['settings_json'] = Variable<String>(settingsJson);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      name: Value(name),
      settingsJson: Value(settingsJson),
    );
  }

  factory ProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      name: serializer.fromJson<String>(json['name']),
      settingsJson: serializer.fromJson<String>(json['settingsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'name': serializer.toJson<String>(name),
      'settingsJson': serializer.toJson<String>(settingsJson),
    };
  }

  ProfileRow copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    String? name,
    String? settingsJson,
  }) => ProfileRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    name: name ?? this.name,
    settingsJson: settingsJson ?? this.settingsJson,
  );
  ProfileRow copyWithCompanion(ProfilesCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      name: data.name.present ? data.name.value : this.name,
      settingsJson: data.settingsJson.present
          ? data.settingsJson.value
          : this.settingsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('settingsJson: $settingsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, deleted, name, settingsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.name == this.name &&
          other.settingsJson == this.settingsJson);
}

class ProfilesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<String> name;
  final Value<String> settingsJson;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.name = const Value.absent(),
    this.settingsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required DateTime updatedAt,
    this.deleted = const Value.absent(),
    required String name,
    required String settingsJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       name = Value(name),
       settingsJson = Value(settingsJson);
  static Insertable<ProfileRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<String>? name,
    Expression<String>? settingsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (name != null) 'name': name,
      if (settingsJson != null) 'settings_json': settingsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<String>? name,
    Value<String>? settingsJson,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      name: name ?? this.name,
      settingsJson: settingsJson ?? this.settingsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (settingsJson.present) {
      map['settings_json'] = Variable<String>(settingsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('settingsJson: $settingsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SnapshotsTable extends Snapshots
    with TableInfo<$SnapshotsTable, SnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> eurRate =
      GeneratedColumn<String>(
        'eur_rate',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($SnapshotsTable.$convertereurRate);
  static const VerificationMeta _rateSourceMeta = const VerificationMeta(
    'rateSource',
  );
  @override
  late final GeneratedColumn<String> rateSource = GeneratedColumn<String>(
    'rate_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rateDateMeta = const VerificationMeta(
    'rateDate',
  );
  @override
  late final GeneratedColumn<String> rateDate = GeneratedColumn<String>(
    'rate_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> millions =
      GeneratedColumn<String>(
        'millions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($SnapshotsTable.$convertermillions);
  static const VerificationMeta _sellersJsonMeta = const VerificationMeta(
    'sellersJson',
  );
  @override
  late final GeneratedColumn<String> sellersJson = GeneratedColumn<String>(
    'sellers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal?, String>
  officialEurPerMillion = GeneratedColumn<String>(
    'official_eur_per_million',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<Decimal?>($SnapshotsTable.$converterofficialEurPerMillionn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    takenAt,
    currency,
    eurRate,
    rateSource,
    rateDate,
    millions,
    sellersJson,
    officialEurPerMillion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<SnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('rate_source')) {
      context.handle(
        _rateSourceMeta,
        rateSource.isAcceptableOrUnknown(data['rate_source']!, _rateSourceMeta),
      );
    } else if (isInserting) {
      context.missing(_rateSourceMeta);
    }
    if (data.containsKey('rate_date')) {
      context.handle(
        _rateDateMeta,
        rateDate.isAcceptableOrUnknown(data['rate_date']!, _rateDateMeta),
      );
    }
    if (data.containsKey('sellers_json')) {
      context.handle(
        _sellersJsonMeta,
        sellersJson.isAcceptableOrUnknown(
          data['sellers_json']!,
          _sellersJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sellersJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SnapshotRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      eurRate: $SnapshotsTable.$convertereurRate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}eur_rate'],
        )!,
      ),
      rateSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rate_source'],
      )!,
      rateDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rate_date'],
      ),
      millions: $SnapshotsTable.$convertermillions.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}millions'],
        )!,
      ),
      sellersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sellers_json'],
      )!,
      officialEurPerMillion: $SnapshotsTable.$converterofficialEurPerMillionn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}official_eur_per_million'],
            ),
          ),
    );
  }

  @override
  $SnapshotsTable createAlias(String alias) {
    return $SnapshotsTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $convertereurRate =
      const DecimalConverter();
  static TypeConverter<Decimal, String> $convertermillions =
      const DecimalConverter();
  static TypeConverter<Decimal, String> $converterofficialEurPerMillion =
      const DecimalConverter();
  static TypeConverter<Decimal?, String?> $converterofficialEurPerMillionn =
      NullAwareTypeConverter.wrap($converterofficialEurPerMillion);
}

class SnapshotRow extends DataClass implements Insertable<SnapshotRow> {
  /// Globally unique record id.
  final String id;

  /// When this record last changed, on any device.
  final DateTime updatedAt;

  /// Whether the record was deleted.
  final bool deleted;

  /// Capture time.
  final DateTime takenAt;

  /// Calculator currency at capture.
  final String currency;

  /// Units of currency per 1 EUR at capture.
  final Decimal eurRate;

  /// Rate source label.
  final String rateSource;

  /// Rate publication date.
  final String? rateDate;

  /// Kina amount in millions.
  final Decimal millions;

  /// Seller prices as a JSON list.
  final String sellersJson;

  /// Official EUR per 1M, if valid.
  final Decimal? officialEurPerMillion;
  const SnapshotRow({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.takenAt,
    required this.currency,
    required this.eurRate,
    required this.rateSource,
    this.rateDate,
    required this.millions,
    required this.sellersJson,
    this.officialEurPerMillion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['taken_at'] = Variable<DateTime>(takenAt);
    map['currency'] = Variable<String>(currency);
    {
      map['eur_rate'] = Variable<String>(
        $SnapshotsTable.$convertereurRate.toSql(eurRate),
      );
    }
    map['rate_source'] = Variable<String>(rateSource);
    if (!nullToAbsent || rateDate != null) {
      map['rate_date'] = Variable<String>(rateDate);
    }
    {
      map['millions'] = Variable<String>(
        $SnapshotsTable.$convertermillions.toSql(millions),
      );
    }
    map['sellers_json'] = Variable<String>(sellersJson);
    if (!nullToAbsent || officialEurPerMillion != null) {
      map['official_eur_per_million'] = Variable<String>(
        $SnapshotsTable.$converterofficialEurPerMillionn.toSql(
          officialEurPerMillion,
        ),
      );
    }
    return map;
  }

  SnapshotsCompanion toCompanion(bool nullToAbsent) {
    return SnapshotsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      takenAt: Value(takenAt),
      currency: Value(currency),
      eurRate: Value(eurRate),
      rateSource: Value(rateSource),
      rateDate: rateDate == null && nullToAbsent
          ? const Value.absent()
          : Value(rateDate),
      millions: Value(millions),
      sellersJson: Value(sellersJson),
      officialEurPerMillion: officialEurPerMillion == null && nullToAbsent
          ? const Value.absent()
          : Value(officialEurPerMillion),
    );
  }

  factory SnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SnapshotRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
      currency: serializer.fromJson<String>(json['currency']),
      eurRate: serializer.fromJson<Decimal>(json['eurRate']),
      rateSource: serializer.fromJson<String>(json['rateSource']),
      rateDate: serializer.fromJson<String?>(json['rateDate']),
      millions: serializer.fromJson<Decimal>(json['millions']),
      sellersJson: serializer.fromJson<String>(json['sellersJson']),
      officialEurPerMillion: serializer.fromJson<Decimal?>(
        json['officialEurPerMillion'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'takenAt': serializer.toJson<DateTime>(takenAt),
      'currency': serializer.toJson<String>(currency),
      'eurRate': serializer.toJson<Decimal>(eurRate),
      'rateSource': serializer.toJson<String>(rateSource),
      'rateDate': serializer.toJson<String?>(rateDate),
      'millions': serializer.toJson<Decimal>(millions),
      'sellersJson': serializer.toJson<String>(sellersJson),
      'officialEurPerMillion': serializer.toJson<Decimal?>(
        officialEurPerMillion,
      ),
    };
  }

  SnapshotRow copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    DateTime? takenAt,
    String? currency,
    Decimal? eurRate,
    String? rateSource,
    Value<String?> rateDate = const Value.absent(),
    Decimal? millions,
    String? sellersJson,
    Value<Decimal?> officialEurPerMillion = const Value.absent(),
  }) => SnapshotRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    takenAt: takenAt ?? this.takenAt,
    currency: currency ?? this.currency,
    eurRate: eurRate ?? this.eurRate,
    rateSource: rateSource ?? this.rateSource,
    rateDate: rateDate.present ? rateDate.value : this.rateDate,
    millions: millions ?? this.millions,
    sellersJson: sellersJson ?? this.sellersJson,
    officialEurPerMillion: officialEurPerMillion.present
        ? officialEurPerMillion.value
        : this.officialEurPerMillion,
  );
  SnapshotRow copyWithCompanion(SnapshotsCompanion data) {
    return SnapshotRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      currency: data.currency.present ? data.currency.value : this.currency,
      eurRate: data.eurRate.present ? data.eurRate.value : this.eurRate,
      rateSource: data.rateSource.present
          ? data.rateSource.value
          : this.rateSource,
      rateDate: data.rateDate.present ? data.rateDate.value : this.rateDate,
      millions: data.millions.present ? data.millions.value : this.millions,
      sellersJson: data.sellersJson.present
          ? data.sellersJson.value
          : this.sellersJson,
      officialEurPerMillion: data.officialEurPerMillion.present
          ? data.officialEurPerMillion.value
          : this.officialEurPerMillion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('takenAt: $takenAt, ')
          ..write('currency: $currency, ')
          ..write('eurRate: $eurRate, ')
          ..write('rateSource: $rateSource, ')
          ..write('rateDate: $rateDate, ')
          ..write('millions: $millions, ')
          ..write('sellersJson: $sellersJson, ')
          ..write('officialEurPerMillion: $officialEurPerMillion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deleted,
    takenAt,
    currency,
    eurRate,
    rateSource,
    rateDate,
    millions,
    sellersJson,
    officialEurPerMillion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapshotRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.takenAt == this.takenAt &&
          other.currency == this.currency &&
          other.eurRate == this.eurRate &&
          other.rateSource == this.rateSource &&
          other.rateDate == this.rateDate &&
          other.millions == this.millions &&
          other.sellersJson == this.sellersJson &&
          other.officialEurPerMillion == this.officialEurPerMillion);
}

class SnapshotsCompanion extends UpdateCompanion<SnapshotRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<DateTime> takenAt;
  final Value<String> currency;
  final Value<Decimal> eurRate;
  final Value<String> rateSource;
  final Value<String?> rateDate;
  final Value<Decimal> millions;
  final Value<String> sellersJson;
  final Value<Decimal?> officialEurPerMillion;
  final Value<int> rowid;
  const SnapshotsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.currency = const Value.absent(),
    this.eurRate = const Value.absent(),
    this.rateSource = const Value.absent(),
    this.rateDate = const Value.absent(),
    this.millions = const Value.absent(),
    this.sellersJson = const Value.absent(),
    this.officialEurPerMillion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SnapshotsCompanion.insert({
    required String id,
    required DateTime updatedAt,
    this.deleted = const Value.absent(),
    required DateTime takenAt,
    required String currency,
    required Decimal eurRate,
    required String rateSource,
    this.rateDate = const Value.absent(),
    required Decimal millions,
    required String sellersJson,
    this.officialEurPerMillion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       takenAt = Value(takenAt),
       currency = Value(currency),
       eurRate = Value(eurRate),
       rateSource = Value(rateSource),
       millions = Value(millions),
       sellersJson = Value(sellersJson);
  static Insertable<SnapshotRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<DateTime>? takenAt,
    Expression<String>? currency,
    Expression<String>? eurRate,
    Expression<String>? rateSource,
    Expression<String>? rateDate,
    Expression<String>? millions,
    Expression<String>? sellersJson,
    Expression<String>? officialEurPerMillion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (takenAt != null) 'taken_at': takenAt,
      if (currency != null) 'currency': currency,
      if (eurRate != null) 'eur_rate': eurRate,
      if (rateSource != null) 'rate_source': rateSource,
      if (rateDate != null) 'rate_date': rateDate,
      if (millions != null) 'millions': millions,
      if (sellersJson != null) 'sellers_json': sellersJson,
      if (officialEurPerMillion != null)
        'official_eur_per_million': officialEurPerMillion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SnapshotsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<DateTime>? takenAt,
    Value<String>? currency,
    Value<Decimal>? eurRate,
    Value<String>? rateSource,
    Value<String?>? rateDate,
    Value<Decimal>? millions,
    Value<String>? sellersJson,
    Value<Decimal?>? officialEurPerMillion,
    Value<int>? rowid,
  }) {
    return SnapshotsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      takenAt: takenAt ?? this.takenAt,
      currency: currency ?? this.currency,
      eurRate: eurRate ?? this.eurRate,
      rateSource: rateSource ?? this.rateSource,
      rateDate: rateDate ?? this.rateDate,
      millions: millions ?? this.millions,
      sellersJson: sellersJson ?? this.sellersJson,
      officialEurPerMillion:
          officialEurPerMillion ?? this.officialEurPerMillion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (eurRate.present) {
      map['eur_rate'] = Variable<String>(
        $SnapshotsTable.$convertereurRate.toSql(eurRate.value),
      );
    }
    if (rateSource.present) {
      map['rate_source'] = Variable<String>(rateSource.value);
    }
    if (rateDate.present) {
      map['rate_date'] = Variable<String>(rateDate.value);
    }
    if (millions.present) {
      map['millions'] = Variable<String>(
        $SnapshotsTable.$convertermillions.toSql(millions.value),
      );
    }
    if (sellersJson.present) {
      map['sellers_json'] = Variable<String>(sellersJson.value);
    }
    if (officialEurPerMillion.present) {
      map['official_eur_per_million'] = Variable<String>(
        $SnapshotsTable.$converterofficialEurPerMillionn.toSql(
          officialEurPerMillion.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('takenAt: $takenAt, ')
          ..write('currency: $currency, ')
          ..write('eurRate: $eurRate, ')
          ..write('rateSource: $rateSource, ')
          ..write('rateDate: $rateDate, ')
          ..write('millions: $millions, ')
          ..write('sellersJson: $sellersJson, ')
          ..write('officialEurPerMillion: $officialEurPerMillion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalEntriesTable extends JournalEntries
    with TableInfo<$JournalEntriesTable, JournalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemMeta = const VerificationMeta('item');
  @override
  late final GeneratedColumn<String> item = GeneratedColumn<String>(
    'item',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> kina =
      GeneratedColumn<String>(
        'kina',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($JournalEntriesTable.$converterkina);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> qunaEquivalent =
      GeneratedColumn<String>(
        'quna_equivalent',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($JournalEntriesTable.$converterqunaEquivalent);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> officialEur =
      GeneratedColumn<String>(
        'official_eur',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($JournalEntriesTable.$converterofficialEur);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> rmtEur =
      GeneratedColumn<String>(
        'rmt_eur',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($JournalEntriesTable.$converterrmtEur);
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> fxRatePerEur =
      GeneratedColumn<String>(
        'fx_rate_per_eur',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($JournalEntriesTable.$converterfxRatePerEur);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deleted,
    date,
    item,
    kina,
    qunaEquivalent,
    officialEur,
    rmtEur,
    currency,
    fxRatePerEur,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('item')) {
      context.handle(
        _itemMeta,
        item.isAcceptableOrUnknown(data['item']!, _itemMeta),
      );
    } else if (isInserting) {
      context.missing(_itemMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      item: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item'],
      )!,
      kina: $JournalEntriesTable.$converterkina.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kina'],
        )!,
      ),
      qunaEquivalent: $JournalEntriesTable.$converterqunaEquivalent.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quna_equivalent'],
        )!,
      ),
      officialEur: $JournalEntriesTable.$converterofficialEur.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}official_eur'],
        )!,
      ),
      rmtEur: $JournalEntriesTable.$converterrmtEur.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}rmt_eur'],
        )!,
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      fxRatePerEur: $JournalEntriesTable.$converterfxRatePerEur.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}fx_rate_per_eur'],
        )!,
      ),
    );
  }

  @override
  $JournalEntriesTable createAlias(String alias) {
    return $JournalEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converterkina =
      const DecimalConverter();
  static TypeConverter<Decimal, String> $converterqunaEquivalent =
      const DecimalConverter();
  static TypeConverter<Decimal, String> $converterofficialEur =
      const DecimalConverter();
  static TypeConverter<Decimal, String> $converterrmtEur =
      const DecimalConverter();
  static TypeConverter<Decimal, String> $converterfxRatePerEur =
      const DecimalConverter();
}

class JournalRow extends DataClass implements Insertable<JournalRow> {
  /// Globally unique record id.
  final String id;

  /// When this record last changed, on any device.
  final DateTime updatedAt;

  /// Whether the record was deleted.
  final bool deleted;

  /// When saved.
  final DateTime date;

  /// Item name.
  final String item;

  /// Price in raw Kina.
  final Decimal kina;

  /// Proportional Quna value.
  final Decimal qunaEquivalent;

  /// Official value in EUR.
  final Decimal officialEur;

  /// RMT value in EUR.
  final Decimal rmtEur;

  /// Calculator currency at capture.
  final String currency;

  /// Units of currency per 1 EUR at capture.
  final Decimal fxRatePerEur;
  const JournalRow({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.date,
    required this.item,
    required this.kina,
    required this.qunaEquivalent,
    required this.officialEur,
    required this.rmtEur,
    required this.currency,
    required this.fxRatePerEur,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['date'] = Variable<DateTime>(date);
    map['item'] = Variable<String>(item);
    {
      map['kina'] = Variable<String>(
        $JournalEntriesTable.$converterkina.toSql(kina),
      );
    }
    {
      map['quna_equivalent'] = Variable<String>(
        $JournalEntriesTable.$converterqunaEquivalent.toSql(qunaEquivalent),
      );
    }
    {
      map['official_eur'] = Variable<String>(
        $JournalEntriesTable.$converterofficialEur.toSql(officialEur),
      );
    }
    {
      map['rmt_eur'] = Variable<String>(
        $JournalEntriesTable.$converterrmtEur.toSql(rmtEur),
      );
    }
    map['currency'] = Variable<String>(currency);
    {
      map['fx_rate_per_eur'] = Variable<String>(
        $JournalEntriesTable.$converterfxRatePerEur.toSql(fxRatePerEur),
      );
    }
    return map;
  }

  JournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return JournalEntriesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      date: Value(date),
      item: Value(item),
      kina: Value(kina),
      qunaEquivalent: Value(qunaEquivalent),
      officialEur: Value(officialEur),
      rmtEur: Value(rmtEur),
      currency: Value(currency),
      fxRatePerEur: Value(fxRatePerEur),
    );
  }

  factory JournalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      date: serializer.fromJson<DateTime>(json['date']),
      item: serializer.fromJson<String>(json['item']),
      kina: serializer.fromJson<Decimal>(json['kina']),
      qunaEquivalent: serializer.fromJson<Decimal>(json['qunaEquivalent']),
      officialEur: serializer.fromJson<Decimal>(json['officialEur']),
      rmtEur: serializer.fromJson<Decimal>(json['rmtEur']),
      currency: serializer.fromJson<String>(json['currency']),
      fxRatePerEur: serializer.fromJson<Decimal>(json['fxRatePerEur']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'date': serializer.toJson<DateTime>(date),
      'item': serializer.toJson<String>(item),
      'kina': serializer.toJson<Decimal>(kina),
      'qunaEquivalent': serializer.toJson<Decimal>(qunaEquivalent),
      'officialEur': serializer.toJson<Decimal>(officialEur),
      'rmtEur': serializer.toJson<Decimal>(rmtEur),
      'currency': serializer.toJson<String>(currency),
      'fxRatePerEur': serializer.toJson<Decimal>(fxRatePerEur),
    };
  }

  JournalRow copyWith({
    String? id,
    DateTime? updatedAt,
    bool? deleted,
    DateTime? date,
    String? item,
    Decimal? kina,
    Decimal? qunaEquivalent,
    Decimal? officialEur,
    Decimal? rmtEur,
    String? currency,
    Decimal? fxRatePerEur,
  }) => JournalRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    date: date ?? this.date,
    item: item ?? this.item,
    kina: kina ?? this.kina,
    qunaEquivalent: qunaEquivalent ?? this.qunaEquivalent,
    officialEur: officialEur ?? this.officialEur,
    rmtEur: rmtEur ?? this.rmtEur,
    currency: currency ?? this.currency,
    fxRatePerEur: fxRatePerEur ?? this.fxRatePerEur,
  );
  JournalRow copyWithCompanion(JournalEntriesCompanion data) {
    return JournalRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      date: data.date.present ? data.date.value : this.date,
      item: data.item.present ? data.item.value : this.item,
      kina: data.kina.present ? data.kina.value : this.kina,
      qunaEquivalent: data.qunaEquivalent.present
          ? data.qunaEquivalent.value
          : this.qunaEquivalent,
      officialEur: data.officialEur.present
          ? data.officialEur.value
          : this.officialEur,
      rmtEur: data.rmtEur.present ? data.rmtEur.value : this.rmtEur,
      currency: data.currency.present ? data.currency.value : this.currency,
      fxRatePerEur: data.fxRatePerEur.present
          ? data.fxRatePerEur.value
          : this.fxRatePerEur,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('date: $date, ')
          ..write('item: $item, ')
          ..write('kina: $kina, ')
          ..write('qunaEquivalent: $qunaEquivalent, ')
          ..write('officialEur: $officialEur, ')
          ..write('rmtEur: $rmtEur, ')
          ..write('currency: $currency, ')
          ..write('fxRatePerEur: $fxRatePerEur')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deleted,
    date,
    item,
    kina,
    qunaEquivalent,
    officialEur,
    rmtEur,
    currency,
    fxRatePerEur,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.date == this.date &&
          other.item == this.item &&
          other.kina == this.kina &&
          other.qunaEquivalent == this.qunaEquivalent &&
          other.officialEur == this.officialEur &&
          other.rmtEur == this.rmtEur &&
          other.currency == this.currency &&
          other.fxRatePerEur == this.fxRatePerEur);
}

class JournalEntriesCompanion extends UpdateCompanion<JournalRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<DateTime> date;
  final Value<String> item;
  final Value<Decimal> kina;
  final Value<Decimal> qunaEquivalent;
  final Value<Decimal> officialEur;
  final Value<Decimal> rmtEur;
  final Value<String> currency;
  final Value<Decimal> fxRatePerEur;
  final Value<int> rowid;
  const JournalEntriesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.date = const Value.absent(),
    this.item = const Value.absent(),
    this.kina = const Value.absent(),
    this.qunaEquivalent = const Value.absent(),
    this.officialEur = const Value.absent(),
    this.rmtEur = const Value.absent(),
    this.currency = const Value.absent(),
    this.fxRatePerEur = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalEntriesCompanion.insert({
    required String id,
    required DateTime updatedAt,
    this.deleted = const Value.absent(),
    required DateTime date,
    required String item,
    required Decimal kina,
    required Decimal qunaEquivalent,
    required Decimal officialEur,
    required Decimal rmtEur,
    required String currency,
    required Decimal fxRatePerEur,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       date = Value(date),
       item = Value(item),
       kina = Value(kina),
       qunaEquivalent = Value(qunaEquivalent),
       officialEur = Value(officialEur),
       rmtEur = Value(rmtEur),
       currency = Value(currency),
       fxRatePerEur = Value(fxRatePerEur);
  static Insertable<JournalRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<DateTime>? date,
    Expression<String>? item,
    Expression<String>? kina,
    Expression<String>? qunaEquivalent,
    Expression<String>? officialEur,
    Expression<String>? rmtEur,
    Expression<String>? currency,
    Expression<String>? fxRatePerEur,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (date != null) 'date': date,
      if (item != null) 'item': item,
      if (kina != null) 'kina': kina,
      if (qunaEquivalent != null) 'quna_equivalent': qunaEquivalent,
      if (officialEur != null) 'official_eur': officialEur,
      if (rmtEur != null) 'rmt_eur': rmtEur,
      if (currency != null) 'currency': currency,
      if (fxRatePerEur != null) 'fx_rate_per_eur': fxRatePerEur,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalEntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<bool>? deleted,
    Value<DateTime>? date,
    Value<String>? item,
    Value<Decimal>? kina,
    Value<Decimal>? qunaEquivalent,
    Value<Decimal>? officialEur,
    Value<Decimal>? rmtEur,
    Value<String>? currency,
    Value<Decimal>? fxRatePerEur,
    Value<int>? rowid,
  }) {
    return JournalEntriesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      date: date ?? this.date,
      item: item ?? this.item,
      kina: kina ?? this.kina,
      qunaEquivalent: qunaEquivalent ?? this.qunaEquivalent,
      officialEur: officialEur ?? this.officialEur,
      rmtEur: rmtEur ?? this.rmtEur,
      currency: currency ?? this.currency,
      fxRatePerEur: fxRatePerEur ?? this.fxRatePerEur,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (item.present) {
      map['item'] = Variable<String>(item.value);
    }
    if (kina.present) {
      map['kina'] = Variable<String>(
        $JournalEntriesTable.$converterkina.toSql(kina.value),
      );
    }
    if (qunaEquivalent.present) {
      map['quna_equivalent'] = Variable<String>(
        $JournalEntriesTable.$converterqunaEquivalent.toSql(
          qunaEquivalent.value,
        ),
      );
    }
    if (officialEur.present) {
      map['official_eur'] = Variable<String>(
        $JournalEntriesTable.$converterofficialEur.toSql(officialEur.value),
      );
    }
    if (rmtEur.present) {
      map['rmt_eur'] = Variable<String>(
        $JournalEntriesTable.$converterrmtEur.toSql(rmtEur.value),
      );
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (fxRatePerEur.present) {
      map['fx_rate_per_eur'] = Variable<String>(
        $JournalEntriesTable.$converterfxRatePerEur.toSql(fxRatePerEur.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('date: $date, ')
          ..write('item: $item, ')
          ..write('kina: $kina, ')
          ..write('qunaEquivalent: $qunaEquivalent, ')
          ..write('officialEur: $officialEur, ')
          ..write('rmtEur: $rmtEur, ')
          ..write('currency: $currency, ')
          ..write('fxRatePerEur: $fxRatePerEur, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$KinaDatabase extends GeneratedDatabase {
  _$KinaDatabase(QueryExecutor e) : super(e);
  $KinaDatabaseManager get managers => $KinaDatabaseManager(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $SnapshotsTable snapshots = $SnapshotsTable(this);
  late final $JournalEntriesTable journalEntries = $JournalEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settingsTable,
    profiles,
    snapshots,
    journalEntries,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SettingsTableTableCreateCompanionBuilder =
    SettingsTableCompanion Function({
      required String id,
      required DateTime updatedAt,
      Value<bool> deleted,
      required String json,
      Value<int> rowid,
    });
typedef $$SettingsTableTableUpdateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<String> json,
      Value<int> rowid,
    });

class $$SettingsTableTableFilterComposer
    extends Composer<_$KinaDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$KinaDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$KinaDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$SettingsTableTableTableManager
    extends
        RootTableManager<
          _$KinaDatabase,
          $SettingsTableTable,
          SettingsRow,
          $$SettingsTableTableFilterComposer,
          $$SettingsTableTableOrderingComposer,
          $$SettingsTableTableAnnotationComposer,
          $$SettingsTableTableCreateCompanionBuilder,
          $$SettingsTableTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$KinaDatabase, $SettingsTableTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableTableManager(_$KinaDatabase db, $SettingsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                json: json,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime updatedAt,
                Value<bool> deleted = const Value.absent(),
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                json: json,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTableTable, SettingsRow>(table),
                  BaseReferences<
                    _$KinaDatabase,
                    $SettingsTableTable,
                    SettingsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$KinaDatabase,
      $SettingsTableTable,
      SettingsRow,
      $$SettingsTableTableFilterComposer,
      $$SettingsTableTableOrderingComposer,
      $$SettingsTableTableAnnotationComposer,
      $$SettingsTableTableCreateCompanionBuilder,
      $$SettingsTableTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$KinaDatabase, $SettingsTableTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;
typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      required String id,
      required DateTime updatedAt,
      Value<bool> deleted,
      required String name,
      required String settingsJson,
      Value<int> rowid,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<String> name,
      Value<String> settingsJson,
      Value<int> rowid,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$KinaDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$KinaDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$KinaDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => column,
  );
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$KinaDatabase,
          $ProfilesTable,
          ProfileRow,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (
            ProfileRow,
            BaseReferences<_$KinaDatabase, $ProfilesTable, ProfileRow>,
          ),
          ProfileRow,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$KinaDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> settingsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                name: name,
                settingsJson: settingsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime updatedAt,
                Value<bool> deleted = const Value.absent(),
                required String name,
                required String settingsJson,
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                name: name,
                settingsJson: settingsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTable, ProfileRow>(table),
                  BaseReferences<_$KinaDatabase, $ProfilesTable, ProfileRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$KinaDatabase,
      $ProfilesTable,
      ProfileRow,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (ProfileRow, BaseReferences<_$KinaDatabase, $ProfilesTable, ProfileRow>),
      ProfileRow,
      PrefetchHooks Function()
    >;
typedef $$SnapshotsTableCreateCompanionBuilder =
    SnapshotsCompanion Function({
      required String id,
      required DateTime updatedAt,
      Value<bool> deleted,
      required DateTime takenAt,
      required String currency,
      required Decimal eurRate,
      required String rateSource,
      Value<String?> rateDate,
      required Decimal millions,
      required String sellersJson,
      Value<Decimal?> officialEurPerMillion,
      Value<int> rowid,
    });
typedef $$SnapshotsTableUpdateCompanionBuilder =
    SnapshotsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<DateTime> takenAt,
      Value<String> currency,
      Value<Decimal> eurRate,
      Value<String> rateSource,
      Value<String?> rateDate,
      Value<Decimal> millions,
      Value<String> sellersJson,
      Value<Decimal?> officialEurPerMillion,
      Value<int> rowid,
    });

class $$SnapshotsTableFilterComposer
    extends Composer<_$KinaDatabase, $SnapshotsTable> {
  $$SnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get eurRate =>
      $composableBuilder(
        column: $table.eurRate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get rateSource => $composableBuilder(
    column: $table.rateSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rateDate => $composableBuilder(
    column: $table.rateDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get millions =>
      $composableBuilder(
        column: $table.millions,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get sellersJson => $composableBuilder(
    column: $table.sellersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal?, Decimal, String>
  get officialEurPerMillion => $composableBuilder(
    column: $table.officialEurPerMillion,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$SnapshotsTableOrderingComposer
    extends Composer<_$KinaDatabase, $SnapshotsTable> {
  $$SnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eurRate => $composableBuilder(
    column: $table.eurRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rateSource => $composableBuilder(
    column: $table.rateSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rateDate => $composableBuilder(
    column: $table.rateDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get millions => $composableBuilder(
    column: $table.millions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellersJson => $composableBuilder(
    column: $table.sellersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get officialEurPerMillion => $composableBuilder(
    column: $table.officialEurPerMillion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SnapshotsTableAnnotationComposer
    extends Composer<_$KinaDatabase, $SnapshotsTable> {
  $$SnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get eurRate =>
      $composableBuilder(column: $table.eurRate, builder: (column) => column);

  GeneratedColumn<String> get rateSource => $composableBuilder(
    column: $table.rateSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rateDate =>
      $composableBuilder(column: $table.rateDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get millions =>
      $composableBuilder(column: $table.millions, builder: (column) => column);

  GeneratedColumn<String> get sellersJson => $composableBuilder(
    column: $table.sellersJson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Decimal?, String>
  get officialEurPerMillion => $composableBuilder(
    column: $table.officialEurPerMillion,
    builder: (column) => column,
  );
}

class $$SnapshotsTableTableManager
    extends
        RootTableManager<
          _$KinaDatabase,
          $SnapshotsTable,
          SnapshotRow,
          $$SnapshotsTableFilterComposer,
          $$SnapshotsTableOrderingComposer,
          $$SnapshotsTableAnnotationComposer,
          $$SnapshotsTableCreateCompanionBuilder,
          $$SnapshotsTableUpdateCompanionBuilder,
          (
            SnapshotRow,
            BaseReferences<_$KinaDatabase, $SnapshotsTable, SnapshotRow>,
          ),
          SnapshotRow,
          PrefetchHooks Function()
        > {
  $$SnapshotsTableTableManager(_$KinaDatabase db, $SnapshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<Decimal> eurRate = const Value.absent(),
                Value<String> rateSource = const Value.absent(),
                Value<String?> rateDate = const Value.absent(),
                Value<Decimal> millions = const Value.absent(),
                Value<String> sellersJson = const Value.absent(),
                Value<Decimal?> officialEurPerMillion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SnapshotsCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                takenAt: takenAt,
                currency: currency,
                eurRate: eurRate,
                rateSource: rateSource,
                rateDate: rateDate,
                millions: millions,
                sellersJson: sellersJson,
                officialEurPerMillion: officialEurPerMillion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime updatedAt,
                Value<bool> deleted = const Value.absent(),
                required DateTime takenAt,
                required String currency,
                required Decimal eurRate,
                required String rateSource,
                Value<String?> rateDate = const Value.absent(),
                required Decimal millions,
                required String sellersJson,
                Value<Decimal?> officialEurPerMillion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SnapshotsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                takenAt: takenAt,
                currency: currency,
                eurRate: eurRate,
                rateSource: rateSource,
                rateDate: rateDate,
                millions: millions,
                sellersJson: sellersJson,
                officialEurPerMillion: officialEurPerMillion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SnapshotsTable, SnapshotRow>(table),
                  BaseReferences<_$KinaDatabase, $SnapshotsTable, SnapshotRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$KinaDatabase,
      $SnapshotsTable,
      SnapshotRow,
      $$SnapshotsTableFilterComposer,
      $$SnapshotsTableOrderingComposer,
      $$SnapshotsTableAnnotationComposer,
      $$SnapshotsTableCreateCompanionBuilder,
      $$SnapshotsTableUpdateCompanionBuilder,
      (
        SnapshotRow,
        BaseReferences<_$KinaDatabase, $SnapshotsTable, SnapshotRow>,
      ),
      SnapshotRow,
      PrefetchHooks Function()
    >;
typedef $$JournalEntriesTableCreateCompanionBuilder =
    JournalEntriesCompanion Function({
      required String id,
      required DateTime updatedAt,
      Value<bool> deleted,
      required DateTime date,
      required String item,
      required Decimal kina,
      required Decimal qunaEquivalent,
      required Decimal officialEur,
      required Decimal rmtEur,
      required String currency,
      required Decimal fxRatePerEur,
      Value<int> rowid,
    });
typedef $$JournalEntriesTableUpdateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<bool> deleted,
      Value<DateTime> date,
      Value<String> item,
      Value<Decimal> kina,
      Value<Decimal> qunaEquivalent,
      Value<Decimal> officialEur,
      Value<Decimal> rmtEur,
      Value<String> currency,
      Value<Decimal> fxRatePerEur,
      Value<int> rowid,
    });

class $$JournalEntriesTableFilterComposer
    extends Composer<_$KinaDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get item => $composableBuilder(
    column: $table.item,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get kina =>
      $composableBuilder(
        column: $table.kina,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get qunaEquivalent =>
      $composableBuilder(
        column: $table.qunaEquivalent,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get officialEur =>
      $composableBuilder(
        column: $table.officialEur,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get rmtEur =>
      $composableBuilder(
        column: $table.rmtEur,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get fxRatePerEur =>
      $composableBuilder(
        column: $table.fxRatePerEur,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$JournalEntriesTableOrderingComposer
    extends Composer<_$KinaDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get item => $composableBuilder(
    column: $table.item,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kina => $composableBuilder(
    column: $table.kina,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qunaEquivalent => $composableBuilder(
    column: $table.qunaEquivalent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get officialEur => $composableBuilder(
    column: $table.officialEur,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rmtEur => $composableBuilder(
    column: $table.rmtEur,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fxRatePerEur => $composableBuilder(
    column: $table.fxRatePerEur,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalEntriesTableAnnotationComposer
    extends Composer<_$KinaDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get item =>
      $composableBuilder(column: $table.item, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get kina =>
      $composableBuilder(column: $table.kina, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get qunaEquivalent =>
      $composableBuilder(
        column: $table.qunaEquivalent,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Decimal, String> get officialEur =>
      $composableBuilder(
        column: $table.officialEur,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Decimal, String> get rmtEur =>
      $composableBuilder(column: $table.rmtEur, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get fxRatePerEur =>
      $composableBuilder(
        column: $table.fxRatePerEur,
        builder: (column) => column,
      );
}

class $$JournalEntriesTableTableManager
    extends
        RootTableManager<
          _$KinaDatabase,
          $JournalEntriesTable,
          JournalRow,
          $$JournalEntriesTableFilterComposer,
          $$JournalEntriesTableOrderingComposer,
          $$JournalEntriesTableAnnotationComposer,
          $$JournalEntriesTableCreateCompanionBuilder,
          $$JournalEntriesTableUpdateCompanionBuilder,
          (
            JournalRow,
            BaseReferences<_$KinaDatabase, $JournalEntriesTable, JournalRow>,
          ),
          JournalRow,
          PrefetchHooks Function()
        > {
  $$JournalEntriesTableTableManager(
    _$KinaDatabase db,
    $JournalEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> item = const Value.absent(),
                Value<Decimal> kina = const Value.absent(),
                Value<Decimal> qunaEquivalent = const Value.absent(),
                Value<Decimal> officialEur = const Value.absent(),
                Value<Decimal> rmtEur = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<Decimal> fxRatePerEur = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalEntriesCompanion(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                date: date,
                item: item,
                kina: kina,
                qunaEquivalent: qunaEquivalent,
                officialEur: officialEur,
                rmtEur: rmtEur,
                currency: currency,
                fxRatePerEur: fxRatePerEur,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime updatedAt,
                Value<bool> deleted = const Value.absent(),
                required DateTime date,
                required String item,
                required Decimal kina,
                required Decimal qunaEquivalent,
                required Decimal officialEur,
                required Decimal rmtEur,
                required String currency,
                required Decimal fxRatePerEur,
                Value<int> rowid = const Value.absent(),
              }) => JournalEntriesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deleted: deleted,
                date: date,
                item: item,
                kina: kina,
                qunaEquivalent: qunaEquivalent,
                officialEur: officialEur,
                rmtEur: rmtEur,
                currency: currency,
                fxRatePerEur: fxRatePerEur,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JournalEntriesTable, JournalRow>(table),
                  BaseReferences<
                    _$KinaDatabase,
                    $JournalEntriesTable,
                    JournalRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$KinaDatabase,
      $JournalEntriesTable,
      JournalRow,
      $$JournalEntriesTableFilterComposer,
      $$JournalEntriesTableOrderingComposer,
      $$JournalEntriesTableAnnotationComposer,
      $$JournalEntriesTableCreateCompanionBuilder,
      $$JournalEntriesTableUpdateCompanionBuilder,
      (
        JournalRow,
        BaseReferences<_$KinaDatabase, $JournalEntriesTable, JournalRow>,
      ),
      JournalRow,
      PrefetchHooks Function()
    >;

class $KinaDatabaseManager {
  final _$KinaDatabase _db;
  $KinaDatabaseManager(this._db);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$SnapshotsTableTableManager get snapshots =>
      $$SnapshotsTableTableManager(_db, _db.snapshots);
  $$JournalEntriesTableTableManager get journalEntries =>
      $$JournalEntriesTableTableManager(_db, _db.journalEntries);
}
