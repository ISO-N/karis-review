// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalSettingsTable extends LocalSettings
    with TableInfo<$LocalSettingsTable, LocalSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refreshTimeMeta = const VerificationMeta(
    'refreshTime',
  );
  @override
  late final GeneratedColumn<String> refreshTime = GeneratedColumn<String>(
    'refresh_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(SchedulingConstants.defaultRefreshTime),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, email, refreshTime, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('refresh_time')) {
      context.handle(
        _refreshTimeMeta,
        refreshTime.isAcceptableOrUnknown(
          data['refresh_time']!,
          _refreshTimeMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  LocalSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSetting(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      refreshTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refresh_time'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalSettingsTable createAlias(String alias) {
    return $LocalSettingsTable(attachedDatabase, alias);
  }
}

class LocalSetting extends DataClass implements Insertable<LocalSetting> {
  final String userId;
  final String email;
  final String refreshTime;
  final DateTime? updatedAt;
  const LocalSetting({
    required this.userId,
    required this.email,
    required this.refreshTime,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['email'] = Variable<String>(email);
    map['refresh_time'] = Variable<String>(refreshTime);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsCompanion(
      userId: Value(userId),
      email: Value(email),
      refreshTime: Value(refreshTime),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSetting(
      userId: serializer.fromJson<String>(json['userId']),
      email: serializer.fromJson<String>(json['email']),
      refreshTime: serializer.fromJson<String>(json['refreshTime']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'email': serializer.toJson<String>(email),
      'refreshTime': serializer.toJson<String>(refreshTime),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalSetting copyWith({
    String? userId,
    String? email,
    String? refreshTime,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalSetting(
    userId: userId ?? this.userId,
    email: email ?? this.email,
    refreshTime: refreshTime ?? this.refreshTime,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalSetting copyWithCompanion(LocalSettingsCompanion data) {
    return LocalSetting(
      userId: data.userId.present ? data.userId.value : this.userId,
      email: data.email.present ? data.email.value : this.email,
      refreshTime: data.refreshTime.present
          ? data.refreshTime.value
          : this.refreshTime,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSetting(')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('refreshTime: $refreshTime, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, email, refreshTime, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSetting &&
          other.userId == this.userId &&
          other.email == this.email &&
          other.refreshTime == this.refreshTime &&
          other.updatedAt == this.updatedAt);
}

class LocalSettingsCompanion extends UpdateCompanion<LocalSetting> {
  final Value<String> userId;
  final Value<String> email;
  final Value<String> refreshTime;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalSettingsCompanion({
    this.userId = const Value.absent(),
    this.email = const Value.absent(),
    this.refreshTime = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSettingsCompanion.insert({
    required String userId,
    required String email,
    this.refreshTime = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       email = Value(email);
  static Insertable<LocalSetting> custom({
    Expression<String>? userId,
    Expression<String>? email,
    Expression<String>? refreshTime,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (email != null) 'email': email,
      if (refreshTime != null) 'refresh_time': refreshTime,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSettingsCompanion copyWith({
    Value<String>? userId,
    Value<String>? email,
    Value<String>? refreshTime,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalSettingsCompanion(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      refreshTime: refreshTime ?? this.refreshTime,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (refreshTime.present) {
      map['refresh_time'] = Variable<String>(refreshTime.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsCompanion(')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('refreshTime: $refreshTime, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDecksTable extends LocalDecks
    with TableInfo<$LocalDecksTable, LocalDeck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDecksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_decks';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDeck> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {id, userId},
  ];
  @override
  LocalDeck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDeck(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalDecksTable createAlias(String alias) {
    return $LocalDecksTable(attachedDatabase, alias);
  }
}

class LocalDeck extends DataClass implements Insertable<LocalDeck> {
  final String id;
  final String userId;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const LocalDeck({
    required this.id,
    required this.userId,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalDecksCompanion toCompanion(bool nullToAbsent) {
    return LocalDecksCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalDeck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDeck(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalDeck copyWith({
    String? id,
    String? userId,
    String? name,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalDeck(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalDeck copyWithCompanion(LocalDecksCompanion data) {
    return LocalDeck(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDeck(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, name, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDeck &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalDecksCompanion extends UpdateCompanion<LocalDeck> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalDecksCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDecksCompanion.insert({
    required String id,
    required String userId,
    required String name,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name);
  static Insertable<LocalDeck> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDecksCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalDecksCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDecksCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCardsTable extends LocalCards
    with TableInfo<$LocalCardsTable, LocalCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frontMeta = const VerificationMeta('front');
  @override
  late final GeneratedColumn<String> front = GeneratedColumn<String>(
    'front',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backMeta = const VerificationMeta('back');
  @override
  late final GeneratedColumn<String> back = GeneratedColumn<String>(
    'back',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<int> stage = GeneratedColumn<int>(
    'stage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _consecutiveFamiliarMeta =
      const VerificationMeta('consecutiveFamiliar');
  @override
  late final GeneratedColumn<int> consecutiveFamiliar = GeneratedColumn<int>(
    'consecutive_familiar',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextReviewDateMeta = const VerificationMeta(
    'nextReviewDate',
  );
  @override
  late final GeneratedColumn<String> nextReviewDate = GeneratedColumn<String>(
    'next_review_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _learningModeMeta = const VerificationMeta(
    'learningMode',
  );
  @override
  late final GeneratedColumn<bool> learningMode = GeneratedColumn<bool>(
    'learning_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("learning_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reentryStageMeta = const VerificationMeta(
    'reentryStage',
  );
  @override
  late final GeneratedColumn<int> reentryStage = GeneratedColumn<int>(
    'reentry_stage',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _learningStepMeta = const VerificationMeta(
    'learningStep',
  );
  @override
  late final GeneratedColumn<int> learningStep = GeneratedColumn<int>(
    'learning_step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _learningOriginMeta = const VerificationMeta(
    'learningOrigin',
  );
  @override
  late final GeneratedColumn<String> learningOrigin = GeneratedColumn<String>(
    'learning_origin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewVersionMeta = const VerificationMeta(
    'reviewVersion',
  );
  @override
  late final GeneratedColumn<BigInt> reviewVersion = GeneratedColumn<BigInt>(
    'review_version',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
    defaultValue: Constant(BigInt.zero),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deckId,
    userId,
    front,
    back,
    stage,
    consecutiveFamiliar,
    nextReviewDate,
    learningMode,
    reentryStage,
    learningStep,
    learningOrigin,
    reviewVersion,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('front')) {
      context.handle(
        _frontMeta,
        front.isAcceptableOrUnknown(data['front']!, _frontMeta),
      );
    } else if (isInserting) {
      context.missing(_frontMeta);
    }
    if (data.containsKey('back')) {
      context.handle(
        _backMeta,
        back.isAcceptableOrUnknown(data['back']!, _backMeta),
      );
    } else if (isInserting) {
      context.missing(_backMeta);
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    }
    if (data.containsKey('consecutive_familiar')) {
      context.handle(
        _consecutiveFamiliarMeta,
        consecutiveFamiliar.isAcceptableOrUnknown(
          data['consecutive_familiar']!,
          _consecutiveFamiliarMeta,
        ),
      );
    }
    if (data.containsKey('next_review_date')) {
      context.handle(
        _nextReviewDateMeta,
        nextReviewDate.isAcceptableOrUnknown(
          data['next_review_date']!,
          _nextReviewDateMeta,
        ),
      );
    }
    if (data.containsKey('learning_mode')) {
      context.handle(
        _learningModeMeta,
        learningMode.isAcceptableOrUnknown(
          data['learning_mode']!,
          _learningModeMeta,
        ),
      );
    }
    if (data.containsKey('reentry_stage')) {
      context.handle(
        _reentryStageMeta,
        reentryStage.isAcceptableOrUnknown(
          data['reentry_stage']!,
          _reentryStageMeta,
        ),
      );
    }
    if (data.containsKey('learning_step')) {
      context.handle(
        _learningStepMeta,
        learningStep.isAcceptableOrUnknown(
          data['learning_step']!,
          _learningStepMeta,
        ),
      );
    }
    if (data.containsKey('learning_origin')) {
      context.handle(
        _learningOriginMeta,
        learningOrigin.isAcceptableOrUnknown(
          data['learning_origin']!,
          _learningOriginMeta,
        ),
      );
    }
    if (data.containsKey('review_version')) {
      context.handle(
        _reviewVersionMeta,
        reviewVersion.isAcceptableOrUnknown(
          data['review_version']!,
          _reviewVersionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {id, userId},
  ];
  @override
  LocalCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      front: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}front'],
      )!,
      back: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}back'],
      )!,
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage'],
      )!,
      consecutiveFamiliar: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consecutive_familiar'],
      )!,
      nextReviewDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_review_date'],
      ),
      learningMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}learning_mode'],
      )!,
      reentryStage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reentry_stage'],
      ),
      learningStep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learning_step'],
      )!,
      learningOrigin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learning_origin'],
      ),
      reviewVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}review_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalCardsTable createAlias(String alias) {
    return $LocalCardsTable(attachedDatabase, alias);
  }
}

class LocalCard extends DataClass implements Insertable<LocalCard> {
  final String id;
  final String deckId;
  final String userId;
  final String front;
  final String back;
  final int stage;
  final int consecutiveFamiliar;
  final String? nextReviewDate;
  final bool learningMode;
  final int? reentryStage;
  final int learningStep;
  final String? learningOrigin;
  final BigInt reviewVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const LocalCard({
    required this.id,
    required this.deckId,
    required this.userId,
    required this.front,
    required this.back,
    required this.stage,
    required this.consecutiveFamiliar,
    this.nextReviewDate,
    required this.learningMode,
    this.reentryStage,
    required this.learningStep,
    this.learningOrigin,
    required this.reviewVersion,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['deck_id'] = Variable<String>(deckId);
    map['user_id'] = Variable<String>(userId);
    map['front'] = Variable<String>(front);
    map['back'] = Variable<String>(back);
    map['stage'] = Variable<int>(stage);
    map['consecutive_familiar'] = Variable<int>(consecutiveFamiliar);
    if (!nullToAbsent || nextReviewDate != null) {
      map['next_review_date'] = Variable<String>(nextReviewDate);
    }
    map['learning_mode'] = Variable<bool>(learningMode);
    if (!nullToAbsent || reentryStage != null) {
      map['reentry_stage'] = Variable<int>(reentryStage);
    }
    map['learning_step'] = Variable<int>(learningStep);
    if (!nullToAbsent || learningOrigin != null) {
      map['learning_origin'] = Variable<String>(learningOrigin);
    }
    map['review_version'] = Variable<BigInt>(reviewVersion);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalCardsCompanion toCompanion(bool nullToAbsent) {
    return LocalCardsCompanion(
      id: Value(id),
      deckId: Value(deckId),
      userId: Value(userId),
      front: Value(front),
      back: Value(back),
      stage: Value(stage),
      consecutiveFamiliar: Value(consecutiveFamiliar),
      nextReviewDate: nextReviewDate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReviewDate),
      learningMode: Value(learningMode),
      reentryStage: reentryStage == null && nullToAbsent
          ? const Value.absent()
          : Value(reentryStage),
      learningStep: Value(learningStep),
      learningOrigin: learningOrigin == null && nullToAbsent
          ? const Value.absent()
          : Value(learningOrigin),
      reviewVersion: Value(reviewVersion),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCard(
      id: serializer.fromJson<String>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      userId: serializer.fromJson<String>(json['userId']),
      front: serializer.fromJson<String>(json['front']),
      back: serializer.fromJson<String>(json['back']),
      stage: serializer.fromJson<int>(json['stage']),
      consecutiveFamiliar: serializer.fromJson<int>(
        json['consecutiveFamiliar'],
      ),
      nextReviewDate: serializer.fromJson<String?>(json['nextReviewDate']),
      learningMode: serializer.fromJson<bool>(json['learningMode']),
      reentryStage: serializer.fromJson<int?>(json['reentryStage']),
      learningStep: serializer.fromJson<int>(json['learningStep']),
      learningOrigin: serializer.fromJson<String?>(json['learningOrigin']),
      reviewVersion: serializer.fromJson<BigInt>(json['reviewVersion']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deckId': serializer.toJson<String>(deckId),
      'userId': serializer.toJson<String>(userId),
      'front': serializer.toJson<String>(front),
      'back': serializer.toJson<String>(back),
      'stage': serializer.toJson<int>(stage),
      'consecutiveFamiliar': serializer.toJson<int>(consecutiveFamiliar),
      'nextReviewDate': serializer.toJson<String?>(nextReviewDate),
      'learningMode': serializer.toJson<bool>(learningMode),
      'reentryStage': serializer.toJson<int?>(reentryStage),
      'learningStep': serializer.toJson<int>(learningStep),
      'learningOrigin': serializer.toJson<String?>(learningOrigin),
      'reviewVersion': serializer.toJson<BigInt>(reviewVersion),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalCard copyWith({
    String? id,
    String? deckId,
    String? userId,
    String? front,
    String? back,
    int? stage,
    int? consecutiveFamiliar,
    Value<String?> nextReviewDate = const Value.absent(),
    bool? learningMode,
    Value<int?> reentryStage = const Value.absent(),
    int? learningStep,
    Value<String?> learningOrigin = const Value.absent(),
    BigInt? reviewVersion,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalCard(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    userId: userId ?? this.userId,
    front: front ?? this.front,
    back: back ?? this.back,
    stage: stage ?? this.stage,
    consecutiveFamiliar: consecutiveFamiliar ?? this.consecutiveFamiliar,
    nextReviewDate: nextReviewDate.present
        ? nextReviewDate.value
        : this.nextReviewDate,
    learningMode: learningMode ?? this.learningMode,
    reentryStage: reentryStage.present ? reentryStage.value : this.reentryStage,
    learningStep: learningStep ?? this.learningStep,
    learningOrigin: learningOrigin.present
        ? learningOrigin.value
        : this.learningOrigin,
    reviewVersion: reviewVersion ?? this.reviewVersion,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalCard copyWithCompanion(LocalCardsCompanion data) {
    return LocalCard(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      userId: data.userId.present ? data.userId.value : this.userId,
      front: data.front.present ? data.front.value : this.front,
      back: data.back.present ? data.back.value : this.back,
      stage: data.stage.present ? data.stage.value : this.stage,
      consecutiveFamiliar: data.consecutiveFamiliar.present
          ? data.consecutiveFamiliar.value
          : this.consecutiveFamiliar,
      nextReviewDate: data.nextReviewDate.present
          ? data.nextReviewDate.value
          : this.nextReviewDate,
      learningMode: data.learningMode.present
          ? data.learningMode.value
          : this.learningMode,
      reentryStage: data.reentryStage.present
          ? data.reentryStage.value
          : this.reentryStage,
      learningStep: data.learningStep.present
          ? data.learningStep.value
          : this.learningStep,
      learningOrigin: data.learningOrigin.present
          ? data.learningOrigin.value
          : this.learningOrigin,
      reviewVersion: data.reviewVersion.present
          ? data.reviewVersion.value
          : this.reviewVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCard(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('userId: $userId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('stage: $stage, ')
          ..write('consecutiveFamiliar: $consecutiveFamiliar, ')
          ..write('nextReviewDate: $nextReviewDate, ')
          ..write('learningMode: $learningMode, ')
          ..write('reentryStage: $reentryStage, ')
          ..write('learningStep: $learningStep, ')
          ..write('learningOrigin: $learningOrigin, ')
          ..write('reviewVersion: $reviewVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deckId,
    userId,
    front,
    back,
    stage,
    consecutiveFamiliar,
    nextReviewDate,
    learningMode,
    reentryStage,
    learningStep,
    learningOrigin,
    reviewVersion,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCard &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.userId == this.userId &&
          other.front == this.front &&
          other.back == this.back &&
          other.stage == this.stage &&
          other.consecutiveFamiliar == this.consecutiveFamiliar &&
          other.nextReviewDate == this.nextReviewDate &&
          other.learningMode == this.learningMode &&
          other.reentryStage == this.reentryStage &&
          other.learningStep == this.learningStep &&
          other.learningOrigin == this.learningOrigin &&
          other.reviewVersion == this.reviewVersion &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalCardsCompanion extends UpdateCompanion<LocalCard> {
  final Value<String> id;
  final Value<String> deckId;
  final Value<String> userId;
  final Value<String> front;
  final Value<String> back;
  final Value<int> stage;
  final Value<int> consecutiveFamiliar;
  final Value<String?> nextReviewDate;
  final Value<bool> learningMode;
  final Value<int?> reentryStage;
  final Value<int> learningStep;
  final Value<String?> learningOrigin;
  final Value<BigInt> reviewVersion;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalCardsCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.userId = const Value.absent(),
    this.front = const Value.absent(),
    this.back = const Value.absent(),
    this.stage = const Value.absent(),
    this.consecutiveFamiliar = const Value.absent(),
    this.nextReviewDate = const Value.absent(),
    this.learningMode = const Value.absent(),
    this.reentryStage = const Value.absent(),
    this.learningStep = const Value.absent(),
    this.learningOrigin = const Value.absent(),
    this.reviewVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCardsCompanion.insert({
    required String id,
    required String deckId,
    required String userId,
    required String front,
    required String back,
    this.stage = const Value.absent(),
    this.consecutiveFamiliar = const Value.absent(),
    this.nextReviewDate = const Value.absent(),
    this.learningMode = const Value.absent(),
    this.reentryStage = const Value.absent(),
    this.learningStep = const Value.absent(),
    this.learningOrigin = const Value.absent(),
    this.reviewVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deckId = Value(deckId),
       userId = Value(userId),
       front = Value(front),
       back = Value(back);
  static Insertable<LocalCard> custom({
    Expression<String>? id,
    Expression<String>? deckId,
    Expression<String>? userId,
    Expression<String>? front,
    Expression<String>? back,
    Expression<int>? stage,
    Expression<int>? consecutiveFamiliar,
    Expression<String>? nextReviewDate,
    Expression<bool>? learningMode,
    Expression<int>? reentryStage,
    Expression<int>? learningStep,
    Expression<String>? learningOrigin,
    Expression<BigInt>? reviewVersion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (userId != null) 'user_id': userId,
      if (front != null) 'front': front,
      if (back != null) 'back': back,
      if (stage != null) 'stage': stage,
      if (consecutiveFamiliar != null)
        'consecutive_familiar': consecutiveFamiliar,
      if (nextReviewDate != null) 'next_review_date': nextReviewDate,
      if (learningMode != null) 'learning_mode': learningMode,
      if (reentryStage != null) 'reentry_stage': reentryStage,
      if (learningStep != null) 'learning_step': learningStep,
      if (learningOrigin != null) 'learning_origin': learningOrigin,
      if (reviewVersion != null) 'review_version': reviewVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCardsCompanion copyWith({
    Value<String>? id,
    Value<String>? deckId,
    Value<String>? userId,
    Value<String>? front,
    Value<String>? back,
    Value<int>? stage,
    Value<int>? consecutiveFamiliar,
    Value<String?>? nextReviewDate,
    Value<bool>? learningMode,
    Value<int?>? reentryStage,
    Value<int>? learningStep,
    Value<String?>? learningOrigin,
    Value<BigInt>? reviewVersion,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalCardsCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      userId: userId ?? this.userId,
      front: front ?? this.front,
      back: back ?? this.back,
      stage: stage ?? this.stage,
      consecutiveFamiliar: consecutiveFamiliar ?? this.consecutiveFamiliar,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      learningMode: learningMode ?? this.learningMode,
      reentryStage: reentryStage ?? this.reentryStage,
      learningStep: learningStep ?? this.learningStep,
      learningOrigin: learningOrigin ?? this.learningOrigin,
      reviewVersion: reviewVersion ?? this.reviewVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (front.present) {
      map['front'] = Variable<String>(front.value);
    }
    if (back.present) {
      map['back'] = Variable<String>(back.value);
    }
    if (stage.present) {
      map['stage'] = Variable<int>(stage.value);
    }
    if (consecutiveFamiliar.present) {
      map['consecutive_familiar'] = Variable<int>(consecutiveFamiliar.value);
    }
    if (nextReviewDate.present) {
      map['next_review_date'] = Variable<String>(nextReviewDate.value);
    }
    if (learningMode.present) {
      map['learning_mode'] = Variable<bool>(learningMode.value);
    }
    if (reentryStage.present) {
      map['reentry_stage'] = Variable<int>(reentryStage.value);
    }
    if (learningStep.present) {
      map['learning_step'] = Variable<int>(learningStep.value);
    }
    if (learningOrigin.present) {
      map['learning_origin'] = Variable<String>(learningOrigin.value);
    }
    if (reviewVersion.present) {
      map['review_version'] = Variable<BigInt>(reviewVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCardsCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('userId: $userId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('stage: $stage, ')
          ..write('consecutiveFamiliar: $consecutiveFamiliar, ')
          ..write('nextReviewDate: $nextReviewDate, ')
          ..write('learningMode: $learningMode, ')
          ..write('reentryStage: $reentryStage, ')
          ..write('learningStep: $learningStep, ')
          ..write('learningOrigin: $learningOrigin, ')
          ..write('reviewVersion: $reviewVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalReviewLogsTable extends LocalReviewLogs
    with TableInfo<$LocalReviewLogsTable, LocalReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageBeforeMeta = const VerificationMeta(
    'stageBefore',
  );
  @override
  late final GeneratedColumn<int> stageBefore = GeneratedColumn<int>(
    'stage_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageAfterMeta = const VerificationMeta(
    'stageAfter',
  );
  @override
  late final GeneratedColumn<int> stageAfter = GeneratedColumn<int>(
    'stage_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isNewCardMeta = const VerificationMeta(
    'isNewCard',
  );
  @override
  late final GeneratedColumn<bool> isNewCard = GeneratedColumn<bool>(
    'is_new_card',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_new_card" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _learningOriginMeta = const VerificationMeta(
    'learningOrigin',
  );
  @override
  late final GeneratedColumn<String> learningOrigin = GeneratedColumn<String>(
    'learning_origin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRequestIdMeta = const VerificationMeta(
    'clientRequestId',
  );
  @override
  late final GeneratedColumn<String> clientRequestId = GeneratedColumn<String>(
    'client_request_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewVersionMeta = const VerificationMeta(
    'reviewVersion',
  );
  @override
  late final GeneratedColumn<BigInt> reviewVersion = GeneratedColumn<BigInt>(
    'review_version',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
    defaultValue: Constant(BigInt.zero),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    cardId,
    rating,
    stageBefore,
    stageAfter,
    isNewCard,
    learningOrigin,
    reviewedAt,
    clientRequestId,
    reviewVersion,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_review_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalReviewLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('stage_before')) {
      context.handle(
        _stageBeforeMeta,
        stageBefore.isAcceptableOrUnknown(
          data['stage_before']!,
          _stageBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stageBeforeMeta);
    }
    if (data.containsKey('stage_after')) {
      context.handle(
        _stageAfterMeta,
        stageAfter.isAcceptableOrUnknown(data['stage_after']!, _stageAfterMeta),
      );
    } else if (isInserting) {
      context.missing(_stageAfterMeta);
    }
    if (data.containsKey('is_new_card')) {
      context.handle(
        _isNewCardMeta,
        isNewCard.isAcceptableOrUnknown(data['is_new_card']!, _isNewCardMeta),
      );
    }
    if (data.containsKey('learning_origin')) {
      context.handle(
        _learningOriginMeta,
        learningOrigin.isAcceptableOrUnknown(
          data['learning_origin']!,
          _learningOriginMeta,
        ),
      );
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('client_request_id')) {
      context.handle(
        _clientRequestIdMeta,
        clientRequestId.isAcceptableOrUnknown(
          data['client_request_id']!,
          _clientRequestIdMeta,
        ),
      );
    }
    if (data.containsKey('review_version')) {
      context.handle(
        _reviewVersionMeta,
        reviewVersion.isAcceptableOrUnknown(
          data['review_version']!,
          _reviewVersionMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalReviewLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      )!,
      stageBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_before'],
      )!,
      stageAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_after'],
      )!,
      isNewCard: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_new_card'],
      )!,
      learningOrigin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learning_origin'],
      ),
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
      clientRequestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_request_id'],
      ),
      reviewVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}review_version'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $LocalReviewLogsTable createAlias(String alias) {
    return $LocalReviewLogsTable(attachedDatabase, alias);
  }
}

class LocalReviewLog extends DataClass implements Insertable<LocalReviewLog> {
  final String id;
  final String userId;
  final String cardId;
  final String rating;
  final int stageBefore;
  final int stageAfter;
  final bool isNewCard;
  final String? learningOrigin;
  final DateTime reviewedAt;
  final String? clientRequestId;
  final BigInt reviewVersion;
  final String syncStatus;
  const LocalReviewLog({
    required this.id,
    required this.userId,
    required this.cardId,
    required this.rating,
    required this.stageBefore,
    required this.stageAfter,
    required this.isNewCard,
    this.learningOrigin,
    required this.reviewedAt,
    this.clientRequestId,
    required this.reviewVersion,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['card_id'] = Variable<String>(cardId);
    map['rating'] = Variable<String>(rating);
    map['stage_before'] = Variable<int>(stageBefore);
    map['stage_after'] = Variable<int>(stageAfter);
    map['is_new_card'] = Variable<bool>(isNewCard);
    if (!nullToAbsent || learningOrigin != null) {
      map['learning_origin'] = Variable<String>(learningOrigin);
    }
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    if (!nullToAbsent || clientRequestId != null) {
      map['client_request_id'] = Variable<String>(clientRequestId);
    }
    map['review_version'] = Variable<BigInt>(reviewVersion);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  LocalReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return LocalReviewLogsCompanion(
      id: Value(id),
      userId: Value(userId),
      cardId: Value(cardId),
      rating: Value(rating),
      stageBefore: Value(stageBefore),
      stageAfter: Value(stageAfter),
      isNewCard: Value(isNewCard),
      learningOrigin: learningOrigin == null && nullToAbsent
          ? const Value.absent()
          : Value(learningOrigin),
      reviewedAt: Value(reviewedAt),
      clientRequestId: clientRequestId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientRequestId),
      reviewVersion: Value(reviewVersion),
      syncStatus: Value(syncStatus),
    );
  }

  factory LocalReviewLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalReviewLog(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      cardId: serializer.fromJson<String>(json['cardId']),
      rating: serializer.fromJson<String>(json['rating']),
      stageBefore: serializer.fromJson<int>(json['stageBefore']),
      stageAfter: serializer.fromJson<int>(json['stageAfter']),
      isNewCard: serializer.fromJson<bool>(json['isNewCard']),
      learningOrigin: serializer.fromJson<String?>(json['learningOrigin']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      clientRequestId: serializer.fromJson<String?>(json['clientRequestId']),
      reviewVersion: serializer.fromJson<BigInt>(json['reviewVersion']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'cardId': serializer.toJson<String>(cardId),
      'rating': serializer.toJson<String>(rating),
      'stageBefore': serializer.toJson<int>(stageBefore),
      'stageAfter': serializer.toJson<int>(stageAfter),
      'isNewCard': serializer.toJson<bool>(isNewCard),
      'learningOrigin': serializer.toJson<String?>(learningOrigin),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'clientRequestId': serializer.toJson<String?>(clientRequestId),
      'reviewVersion': serializer.toJson<BigInt>(reviewVersion),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  LocalReviewLog copyWith({
    String? id,
    String? userId,
    String? cardId,
    String? rating,
    int? stageBefore,
    int? stageAfter,
    bool? isNewCard,
    Value<String?> learningOrigin = const Value.absent(),
    DateTime? reviewedAt,
    Value<String?> clientRequestId = const Value.absent(),
    BigInt? reviewVersion,
    String? syncStatus,
  }) => LocalReviewLog(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    cardId: cardId ?? this.cardId,
    rating: rating ?? this.rating,
    stageBefore: stageBefore ?? this.stageBefore,
    stageAfter: stageAfter ?? this.stageAfter,
    isNewCard: isNewCard ?? this.isNewCard,
    learningOrigin: learningOrigin.present
        ? learningOrigin.value
        : this.learningOrigin,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    clientRequestId: clientRequestId.present
        ? clientRequestId.value
        : this.clientRequestId,
    reviewVersion: reviewVersion ?? this.reviewVersion,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  LocalReviewLog copyWithCompanion(LocalReviewLogsCompanion data) {
    return LocalReviewLog(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      rating: data.rating.present ? data.rating.value : this.rating,
      stageBefore: data.stageBefore.present
          ? data.stageBefore.value
          : this.stageBefore,
      stageAfter: data.stageAfter.present
          ? data.stageAfter.value
          : this.stageAfter,
      isNewCard: data.isNewCard.present ? data.isNewCard.value : this.isNewCard,
      learningOrigin: data.learningOrigin.present
          ? data.learningOrigin.value
          : this.learningOrigin,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      clientRequestId: data.clientRequestId.present
          ? data.clientRequestId.value
          : this.clientRequestId,
      reviewVersion: data.reviewVersion.present
          ? data.reviewVersion.value
          : this.reviewVersion,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalReviewLog(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('cardId: $cardId, ')
          ..write('rating: $rating, ')
          ..write('stageBefore: $stageBefore, ')
          ..write('stageAfter: $stageAfter, ')
          ..write('isNewCard: $isNewCard, ')
          ..write('learningOrigin: $learningOrigin, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('clientRequestId: $clientRequestId, ')
          ..write('reviewVersion: $reviewVersion, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    cardId,
    rating,
    stageBefore,
    stageAfter,
    isNewCard,
    learningOrigin,
    reviewedAt,
    clientRequestId,
    reviewVersion,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalReviewLog &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.cardId == this.cardId &&
          other.rating == this.rating &&
          other.stageBefore == this.stageBefore &&
          other.stageAfter == this.stageAfter &&
          other.isNewCard == this.isNewCard &&
          other.learningOrigin == this.learningOrigin &&
          other.reviewedAt == this.reviewedAt &&
          other.clientRequestId == this.clientRequestId &&
          other.reviewVersion == this.reviewVersion &&
          other.syncStatus == this.syncStatus);
}

class LocalReviewLogsCompanion extends UpdateCompanion<LocalReviewLog> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> cardId;
  final Value<String> rating;
  final Value<int> stageBefore;
  final Value<int> stageAfter;
  final Value<bool> isNewCard;
  final Value<String?> learningOrigin;
  final Value<DateTime> reviewedAt;
  final Value<String?> clientRequestId;
  final Value<BigInt> reviewVersion;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const LocalReviewLogsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.rating = const Value.absent(),
    this.stageBefore = const Value.absent(),
    this.stageAfter = const Value.absent(),
    this.isNewCard = const Value.absent(),
    this.learningOrigin = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.clientRequestId = const Value.absent(),
    this.reviewVersion = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalReviewLogsCompanion.insert({
    required String id,
    required String userId,
    required String cardId,
    required String rating,
    required int stageBefore,
    required int stageAfter,
    this.isNewCard = const Value.absent(),
    this.learningOrigin = const Value.absent(),
    required DateTime reviewedAt,
    this.clientRequestId = const Value.absent(),
    this.reviewVersion = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       cardId = Value(cardId),
       rating = Value(rating),
       stageBefore = Value(stageBefore),
       stageAfter = Value(stageAfter),
       reviewedAt = Value(reviewedAt);
  static Insertable<LocalReviewLog> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? cardId,
    Expression<String>? rating,
    Expression<int>? stageBefore,
    Expression<int>? stageAfter,
    Expression<bool>? isNewCard,
    Expression<String>? learningOrigin,
    Expression<DateTime>? reviewedAt,
    Expression<String>? clientRequestId,
    Expression<BigInt>? reviewVersion,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (cardId != null) 'card_id': cardId,
      if (rating != null) 'rating': rating,
      if (stageBefore != null) 'stage_before': stageBefore,
      if (stageAfter != null) 'stage_after': stageAfter,
      if (isNewCard != null) 'is_new_card': isNewCard,
      if (learningOrigin != null) 'learning_origin': learningOrigin,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (clientRequestId != null) 'client_request_id': clientRequestId,
      if (reviewVersion != null) 'review_version': reviewVersion,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalReviewLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? cardId,
    Value<String>? rating,
    Value<int>? stageBefore,
    Value<int>? stageAfter,
    Value<bool>? isNewCard,
    Value<String?>? learningOrigin,
    Value<DateTime>? reviewedAt,
    Value<String?>? clientRequestId,
    Value<BigInt>? reviewVersion,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return LocalReviewLogsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cardId: cardId ?? this.cardId,
      rating: rating ?? this.rating,
      stageBefore: stageBefore ?? this.stageBefore,
      stageAfter: stageAfter ?? this.stageAfter,
      isNewCard: isNewCard ?? this.isNewCard,
      learningOrigin: learningOrigin ?? this.learningOrigin,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      clientRequestId: clientRequestId ?? this.clientRequestId,
      reviewVersion: reviewVersion ?? this.reviewVersion,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (stageBefore.present) {
      map['stage_before'] = Variable<int>(stageBefore.value);
    }
    if (stageAfter.present) {
      map['stage_after'] = Variable<int>(stageAfter.value);
    }
    if (isNewCard.present) {
      map['is_new_card'] = Variable<bool>(isNewCard.value);
    }
    if (learningOrigin.present) {
      map['learning_origin'] = Variable<String>(learningOrigin.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (clientRequestId.present) {
      map['client_request_id'] = Variable<String>(clientRequestId.value);
    }
    if (reviewVersion.present) {
      map['review_version'] = Variable<BigInt>(reviewVersion.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('cardId: $cardId, ')
          ..write('rating: $rating, ')
          ..write('stageBefore: $stageBefore, ')
          ..write('stageAfter: $stageAfter, ')
          ..write('isNewCard: $isNewCard, ')
          ..write('learningOrigin: $learningOrigin, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('clientRequestId: $clientRequestId, ')
          ..write('reviewVersion: $reviewVersion, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refreshTimeMeta = const VerificationMeta(
    'refreshTime',
  );
  @override
  late final GeneratedColumn<String> refreshTime = GeneratedColumn<String>(
    'refresh_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(SchedulingConstants.defaultRefreshTime),
  );
  static const VerificationMeta _lastBootstrapAtMeta = const VerificationMeta(
    'lastBootstrapAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastBootstrapAt =
      GeneratedColumn<DateTime>(
        'last_bootstrap_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _clockOffsetMsMeta = const VerificationMeta(
    'clockOffsetMs',
  );
  @override
  late final GeneratedColumn<int> clockOffsetMs = GeneratedColumn<int>(
    'clock_offset_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastEventCursorMeta = const VerificationMeta(
    'lastEventCursor',
  );
  @override
  late final GeneratedColumn<BigInt> lastEventCursor = GeneratedColumn<BigInt>(
    'last_event_cursor',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
    defaultValue: Constant(BigInt.zero),
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    email,
    refreshTime,
    lastBootstrapAt,
    clockOffsetMs,
    lastEventCursor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('refresh_time')) {
      context.handle(
        _refreshTimeMeta,
        refreshTime.isAcceptableOrUnknown(
          data['refresh_time']!,
          _refreshTimeMeta,
        ),
      );
    }
    if (data.containsKey('last_bootstrap_at')) {
      context.handle(
        _lastBootstrapAtMeta,
        lastBootstrapAt.isAcceptableOrUnknown(
          data['last_bootstrap_at']!,
          _lastBootstrapAtMeta,
        ),
      );
    }
    if (data.containsKey('clock_offset_ms')) {
      context.handle(
        _clockOffsetMsMeta,
        clockOffsetMs.isAcceptableOrUnknown(
          data['clock_offset_ms']!,
          _clockOffsetMsMeta,
        ),
      );
    }
    if (data.containsKey('last_event_cursor')) {
      context.handle(
        _lastEventCursorMeta,
        lastEventCursor.isAcceptableOrUnknown(
          data['last_event_cursor']!,
          _lastEventCursorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  SyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      refreshTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refresh_time'],
      )!,
      lastBootstrapAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_bootstrap_at'],
      ),
      clockOffsetMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}clock_offset_ms'],
      )!,
      lastEventCursor: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}last_event_cursor'],
      )!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaData extends DataClass implements Insertable<SyncMetaData> {
  final String userId;
  final String? email;
  final String refreshTime;
  final DateTime? lastBootstrapAt;
  final int clockOffsetMs;
  final BigInt lastEventCursor;
  const SyncMetaData({
    required this.userId,
    this.email,
    required this.refreshTime,
    this.lastBootstrapAt,
    required this.clockOffsetMs,
    required this.lastEventCursor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['refresh_time'] = Variable<String>(refreshTime);
    if (!nullToAbsent || lastBootstrapAt != null) {
      map['last_bootstrap_at'] = Variable<DateTime>(lastBootstrapAt);
    }
    map['clock_offset_ms'] = Variable<int>(clockOffsetMs);
    map['last_event_cursor'] = Variable<BigInt>(lastEventCursor);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(
      userId: Value(userId),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      refreshTime: Value(refreshTime),
      lastBootstrapAt: lastBootstrapAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBootstrapAt),
      clockOffsetMs: Value(clockOffsetMs),
      lastEventCursor: Value(lastEventCursor),
    );
  }

  factory SyncMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaData(
      userId: serializer.fromJson<String>(json['userId']),
      email: serializer.fromJson<String?>(json['email']),
      refreshTime: serializer.fromJson<String>(json['refreshTime']),
      lastBootstrapAt: serializer.fromJson<DateTime?>(json['lastBootstrapAt']),
      clockOffsetMs: serializer.fromJson<int>(json['clockOffsetMs']),
      lastEventCursor: serializer.fromJson<BigInt>(json['lastEventCursor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'email': serializer.toJson<String?>(email),
      'refreshTime': serializer.toJson<String>(refreshTime),
      'lastBootstrapAt': serializer.toJson<DateTime?>(lastBootstrapAt),
      'clockOffsetMs': serializer.toJson<int>(clockOffsetMs),
      'lastEventCursor': serializer.toJson<BigInt>(lastEventCursor),
    };
  }

  SyncMetaData copyWith({
    String? userId,
    Value<String?> email = const Value.absent(),
    String? refreshTime,
    Value<DateTime?> lastBootstrapAt = const Value.absent(),
    int? clockOffsetMs,
    BigInt? lastEventCursor,
  }) => SyncMetaData(
    userId: userId ?? this.userId,
    email: email.present ? email.value : this.email,
    refreshTime: refreshTime ?? this.refreshTime,
    lastBootstrapAt: lastBootstrapAt.present
        ? lastBootstrapAt.value
        : this.lastBootstrapAt,
    clockOffsetMs: clockOffsetMs ?? this.clockOffsetMs,
    lastEventCursor: lastEventCursor ?? this.lastEventCursor,
  );
  SyncMetaData copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaData(
      userId: data.userId.present ? data.userId.value : this.userId,
      email: data.email.present ? data.email.value : this.email,
      refreshTime: data.refreshTime.present
          ? data.refreshTime.value
          : this.refreshTime,
      lastBootstrapAt: data.lastBootstrapAt.present
          ? data.lastBootstrapAt.value
          : this.lastBootstrapAt,
      clockOffsetMs: data.clockOffsetMs.present
          ? data.clockOffsetMs.value
          : this.clockOffsetMs,
      lastEventCursor: data.lastEventCursor.present
          ? data.lastEventCursor.value
          : this.lastEventCursor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaData(')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('refreshTime: $refreshTime, ')
          ..write('lastBootstrapAt: $lastBootstrapAt, ')
          ..write('clockOffsetMs: $clockOffsetMs, ')
          ..write('lastEventCursor: $lastEventCursor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    email,
    refreshTime,
    lastBootstrapAt,
    clockOffsetMs,
    lastEventCursor,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaData &&
          other.userId == this.userId &&
          other.email == this.email &&
          other.refreshTime == this.refreshTime &&
          other.lastBootstrapAt == this.lastBootstrapAt &&
          other.clockOffsetMs == this.clockOffsetMs &&
          other.lastEventCursor == this.lastEventCursor);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaData> {
  final Value<String> userId;
  final Value<String?> email;
  final Value<String> refreshTime;
  final Value<DateTime?> lastBootstrapAt;
  final Value<int> clockOffsetMs;
  final Value<BigInt> lastEventCursor;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.userId = const Value.absent(),
    this.email = const Value.absent(),
    this.refreshTime = const Value.absent(),
    this.lastBootstrapAt = const Value.absent(),
    this.clockOffsetMs = const Value.absent(),
    this.lastEventCursor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String userId,
    this.email = const Value.absent(),
    this.refreshTime = const Value.absent(),
    this.lastBootstrapAt = const Value.absent(),
    this.clockOffsetMs = const Value.absent(),
    this.lastEventCursor = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<SyncMetaData> custom({
    Expression<String>? userId,
    Expression<String>? email,
    Expression<String>? refreshTime,
    Expression<DateTime>? lastBootstrapAt,
    Expression<int>? clockOffsetMs,
    Expression<BigInt>? lastEventCursor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (email != null) 'email': email,
      if (refreshTime != null) 'refresh_time': refreshTime,
      if (lastBootstrapAt != null) 'last_bootstrap_at': lastBootstrapAt,
      if (clockOffsetMs != null) 'clock_offset_ms': clockOffsetMs,
      if (lastEventCursor != null) 'last_event_cursor': lastEventCursor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith({
    Value<String>? userId,
    Value<String?>? email,
    Value<String>? refreshTime,
    Value<DateTime?>? lastBootstrapAt,
    Value<int>? clockOffsetMs,
    Value<BigInt>? lastEventCursor,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      refreshTime: refreshTime ?? this.refreshTime,
      lastBootstrapAt: lastBootstrapAt ?? this.lastBootstrapAt,
      clockOffsetMs: clockOffsetMs ?? this.clockOffsetMs,
      lastEventCursor: lastEventCursor ?? this.lastEventCursor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (refreshTime.present) {
      map['refresh_time'] = Variable<String>(refreshTime.value);
    }
    if (lastBootstrapAt.present) {
      map['last_bootstrap_at'] = Variable<DateTime>(lastBootstrapAt.value);
    }
    if (clockOffsetMs.present) {
      map['clock_offset_ms'] = Variable<int>(clockOffsetMs.value);
    }
    if (lastEventCursor.present) {
      map['last_event_cursor'] = Variable<BigInt>(lastEventCursor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('refreshTime: $refreshTime, ')
          ..write('lastBootstrapAt: $lastBootstrapAt, ')
          ..write('clockOffsetMs: $clockOffsetMs, ')
          ..write('lastEventCursor: $lastEventCursor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalSettingsTable localSettings = $LocalSettingsTable(this);
  late final $LocalDecksTable localDecks = $LocalDecksTable(this);
  late final $LocalCardsTable localCards = $LocalCardsTable(this);
  late final $LocalReviewLogsTable localReviewLogs = $LocalReviewLogsTable(
    this,
  );
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localSettings,
    localDecks,
    localCards,
    localReviewLogs,
    syncMeta,
  ];
}

typedef $$LocalSettingsTableCreateCompanionBuilder =
    LocalSettingsCompanion Function({
      required String userId,
      required String email,
      Value<String> refreshTime,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalSettingsTableUpdateCompanionBuilder =
    LocalSettingsCompanion Function({
      Value<String> userId,
      Value<String> email,
      Value<String> refreshTime,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refreshTime => $composableBuilder(
    column: $table.refreshTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refreshTime => $composableBuilder(
    column: $table.refreshTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get refreshTime => $composableBuilder(
    column: $table.refreshTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSettingsTable,
          LocalSetting,
          $$LocalSettingsTableFilterComposer,
          $$LocalSettingsTableOrderingComposer,
          $$LocalSettingsTableAnnotationComposer,
          $$LocalSettingsTableCreateCompanionBuilder,
          $$LocalSettingsTableUpdateCompanionBuilder,
          (
            LocalSetting,
            BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
          ),
          LocalSetting,
          PrefetchHooks Function()
        > {
  $$LocalSettingsTableTableManager(_$AppDatabase db, $LocalSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> refreshTime = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSettingsCompanion(
                userId: userId,
                email: email,
                refreshTime: refreshTime,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String email,
                Value<String> refreshTime = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSettingsCompanion.insert(
                userId: userId,
                email: email,
                refreshTime: refreshTime,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSettingsTable,
      LocalSetting,
      $$LocalSettingsTableFilterComposer,
      $$LocalSettingsTableOrderingComposer,
      $$LocalSettingsTableAnnotationComposer,
      $$LocalSettingsTableCreateCompanionBuilder,
      $$LocalSettingsTableUpdateCompanionBuilder,
      (
        LocalSetting,
        BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
      ),
      LocalSetting,
      PrefetchHooks Function()
    >;
typedef $$LocalDecksTableCreateCompanionBuilder =
    LocalDecksCompanion Function({
      required String id,
      required String userId,
      required String name,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalDecksTableUpdateCompanionBuilder =
    LocalDecksCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalDecksTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDecksTable> {
  $$LocalDecksTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDecksTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDecksTable> {
  $$LocalDecksTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDecksTable> {
  $$LocalDecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalDecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDecksTable,
          LocalDeck,
          $$LocalDecksTableFilterComposer,
          $$LocalDecksTableOrderingComposer,
          $$LocalDecksTableAnnotationComposer,
          $$LocalDecksTableCreateCompanionBuilder,
          $$LocalDecksTableUpdateCompanionBuilder,
          (
            LocalDeck,
            BaseReferences<_$AppDatabase, $LocalDecksTable, LocalDeck>,
          ),
          LocalDeck,
          PrefetchHooks Function()
        > {
  $$LocalDecksTableTableManager(_$AppDatabase db, $LocalDecksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDecksCompanion(
                id: id,
                userId: userId,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String name,
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDecksCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDecksTable,
      LocalDeck,
      $$LocalDecksTableFilterComposer,
      $$LocalDecksTableOrderingComposer,
      $$LocalDecksTableAnnotationComposer,
      $$LocalDecksTableCreateCompanionBuilder,
      $$LocalDecksTableUpdateCompanionBuilder,
      (LocalDeck, BaseReferences<_$AppDatabase, $LocalDecksTable, LocalDeck>),
      LocalDeck,
      PrefetchHooks Function()
    >;
typedef $$LocalCardsTableCreateCompanionBuilder =
    LocalCardsCompanion Function({
      required String id,
      required String deckId,
      required String userId,
      required String front,
      required String back,
      Value<int> stage,
      Value<int> consecutiveFamiliar,
      Value<String?> nextReviewDate,
      Value<bool> learningMode,
      Value<int?> reentryStage,
      Value<int> learningStep,
      Value<String?> learningOrigin,
      Value<BigInt> reviewVersion,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalCardsTableUpdateCompanionBuilder =
    LocalCardsCompanion Function({
      Value<String> id,
      Value<String> deckId,
      Value<String> userId,
      Value<String> front,
      Value<String> back,
      Value<int> stage,
      Value<int> consecutiveFamiliar,
      Value<String?> nextReviewDate,
      Value<bool> learningMode,
      Value<int?> reentryStage,
      Value<int> learningStep,
      Value<String?> learningOrigin,
      Value<BigInt> reviewVersion,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalCardsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCardsTable> {
  $$LocalCardsTableFilterComposer({
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

  ColumnFilters<String> get deckId => $composableBuilder(
    column: $table.deckId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consecutiveFamiliar => $composableBuilder(
    column: $table.consecutiveFamiliar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextReviewDate => $composableBuilder(
    column: $table.nextReviewDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get learningMode => $composableBuilder(
    column: $table.learningMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reentryStage => $composableBuilder(
    column: $table.reentryStage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get learningStep => $composableBuilder(
    column: $table.learningStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get learningOrigin => $composableBuilder(
    column: $table.learningOrigin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get reviewVersion => $composableBuilder(
    column: $table.reviewVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCardsTable> {
  $$LocalCardsTableOrderingComposer({
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

  ColumnOrderings<String> get deckId => $composableBuilder(
    column: $table.deckId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consecutiveFamiliar => $composableBuilder(
    column: $table.consecutiveFamiliar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextReviewDate => $composableBuilder(
    column: $table.nextReviewDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get learningMode => $composableBuilder(
    column: $table.learningMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reentryStage => $composableBuilder(
    column: $table.reentryStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get learningStep => $composableBuilder(
    column: $table.learningStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get learningOrigin => $composableBuilder(
    column: $table.learningOrigin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get reviewVersion => $composableBuilder(
    column: $table.reviewVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCardsTable> {
  $$LocalCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deckId =>
      $composableBuilder(column: $table.deckId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get front =>
      $composableBuilder(column: $table.front, builder: (column) => column);

  GeneratedColumn<String> get back =>
      $composableBuilder(column: $table.back, builder: (column) => column);

  GeneratedColumn<int> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<int> get consecutiveFamiliar => $composableBuilder(
    column: $table.consecutiveFamiliar,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextReviewDate => $composableBuilder(
    column: $table.nextReviewDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get learningMode => $composableBuilder(
    column: $table.learningMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reentryStage => $composableBuilder(
    column: $table.reentryStage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get learningStep => $composableBuilder(
    column: $table.learningStep,
    builder: (column) => column,
  );

  GeneratedColumn<String> get learningOrigin => $composableBuilder(
    column: $table.learningOrigin,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get reviewVersion => $composableBuilder(
    column: $table.reviewVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCardsTable,
          LocalCard,
          $$LocalCardsTableFilterComposer,
          $$LocalCardsTableOrderingComposer,
          $$LocalCardsTableAnnotationComposer,
          $$LocalCardsTableCreateCompanionBuilder,
          $$LocalCardsTableUpdateCompanionBuilder,
          (
            LocalCard,
            BaseReferences<_$AppDatabase, $LocalCardsTable, LocalCard>,
          ),
          LocalCard,
          PrefetchHooks Function()
        > {
  $$LocalCardsTableTableManager(_$AppDatabase db, $LocalCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> front = const Value.absent(),
                Value<String> back = const Value.absent(),
                Value<int> stage = const Value.absent(),
                Value<int> consecutiveFamiliar = const Value.absent(),
                Value<String?> nextReviewDate = const Value.absent(),
                Value<bool> learningMode = const Value.absent(),
                Value<int?> reentryStage = const Value.absent(),
                Value<int> learningStep = const Value.absent(),
                Value<String?> learningOrigin = const Value.absent(),
                Value<BigInt> reviewVersion = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCardsCompanion(
                id: id,
                deckId: deckId,
                userId: userId,
                front: front,
                back: back,
                stage: stage,
                consecutiveFamiliar: consecutiveFamiliar,
                nextReviewDate: nextReviewDate,
                learningMode: learningMode,
                reentryStage: reentryStage,
                learningStep: learningStep,
                learningOrigin: learningOrigin,
                reviewVersion: reviewVersion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deckId,
                required String userId,
                required String front,
                required String back,
                Value<int> stage = const Value.absent(),
                Value<int> consecutiveFamiliar = const Value.absent(),
                Value<String?> nextReviewDate = const Value.absent(),
                Value<bool> learningMode = const Value.absent(),
                Value<int?> reentryStage = const Value.absent(),
                Value<int> learningStep = const Value.absent(),
                Value<String?> learningOrigin = const Value.absent(),
                Value<BigInt> reviewVersion = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCardsCompanion.insert(
                id: id,
                deckId: deckId,
                userId: userId,
                front: front,
                back: back,
                stage: stage,
                consecutiveFamiliar: consecutiveFamiliar,
                nextReviewDate: nextReviewDate,
                learningMode: learningMode,
                reentryStage: reentryStage,
                learningStep: learningStep,
                learningOrigin: learningOrigin,
                reviewVersion: reviewVersion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCardsTable,
      LocalCard,
      $$LocalCardsTableFilterComposer,
      $$LocalCardsTableOrderingComposer,
      $$LocalCardsTableAnnotationComposer,
      $$LocalCardsTableCreateCompanionBuilder,
      $$LocalCardsTableUpdateCompanionBuilder,
      (LocalCard, BaseReferences<_$AppDatabase, $LocalCardsTable, LocalCard>),
      LocalCard,
      PrefetchHooks Function()
    >;
typedef $$LocalReviewLogsTableCreateCompanionBuilder =
    LocalReviewLogsCompanion Function({
      required String id,
      required String userId,
      required String cardId,
      required String rating,
      required int stageBefore,
      required int stageAfter,
      Value<bool> isNewCard,
      Value<String?> learningOrigin,
      required DateTime reviewedAt,
      Value<String?> clientRequestId,
      Value<BigInt> reviewVersion,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$LocalReviewLogsTableUpdateCompanionBuilder =
    LocalReviewLogsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> cardId,
      Value<String> rating,
      Value<int> stageBefore,
      Value<int> stageAfter,
      Value<bool> isNewCard,
      Value<String?> learningOrigin,
      Value<DateTime> reviewedAt,
      Value<String?> clientRequestId,
      Value<BigInt> reviewVersion,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$LocalReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalReviewLogsTable> {
  $$LocalReviewLogsTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stageBefore => $composableBuilder(
    column: $table.stageBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stageAfter => $composableBuilder(
    column: $table.stageAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isNewCard => $composableBuilder(
    column: $table.isNewCard,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get learningOrigin => $composableBuilder(
    column: $table.learningOrigin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientRequestId => $composableBuilder(
    column: $table.clientRequestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get reviewVersion => $composableBuilder(
    column: $table.reviewVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalReviewLogsTable> {
  $$LocalReviewLogsTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stageBefore => $composableBuilder(
    column: $table.stageBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stageAfter => $composableBuilder(
    column: $table.stageAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isNewCard => $composableBuilder(
    column: $table.isNewCard,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get learningOrigin => $composableBuilder(
    column: $table.learningOrigin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientRequestId => $composableBuilder(
    column: $table.clientRequestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get reviewVersion => $composableBuilder(
    column: $table.reviewVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalReviewLogsTable> {
  $$LocalReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get stageBefore => $composableBuilder(
    column: $table.stageBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stageAfter => $composableBuilder(
    column: $table.stageAfter,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isNewCard =>
      $composableBuilder(column: $table.isNewCard, builder: (column) => column);

  GeneratedColumn<String> get learningOrigin => $composableBuilder(
    column: $table.learningOrigin,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientRequestId => $composableBuilder(
    column: $table.clientRequestId,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get reviewVersion => $composableBuilder(
    column: $table.reviewVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$LocalReviewLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalReviewLogsTable,
          LocalReviewLog,
          $$LocalReviewLogsTableFilterComposer,
          $$LocalReviewLogsTableOrderingComposer,
          $$LocalReviewLogsTableAnnotationComposer,
          $$LocalReviewLogsTableCreateCompanionBuilder,
          $$LocalReviewLogsTableUpdateCompanionBuilder,
          (
            LocalReviewLog,
            BaseReferences<
              _$AppDatabase,
              $LocalReviewLogsTable,
              LocalReviewLog
            >,
          ),
          LocalReviewLog,
          PrefetchHooks Function()
        > {
  $$LocalReviewLogsTableTableManager(
    _$AppDatabase db,
    $LocalReviewLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> cardId = const Value.absent(),
                Value<String> rating = const Value.absent(),
                Value<int> stageBefore = const Value.absent(),
                Value<int> stageAfter = const Value.absent(),
                Value<bool> isNewCard = const Value.absent(),
                Value<String?> learningOrigin = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<String?> clientRequestId = const Value.absent(),
                Value<BigInt> reviewVersion = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalReviewLogsCompanion(
                id: id,
                userId: userId,
                cardId: cardId,
                rating: rating,
                stageBefore: stageBefore,
                stageAfter: stageAfter,
                isNewCard: isNewCard,
                learningOrigin: learningOrigin,
                reviewedAt: reviewedAt,
                clientRequestId: clientRequestId,
                reviewVersion: reviewVersion,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String cardId,
                required String rating,
                required int stageBefore,
                required int stageAfter,
                Value<bool> isNewCard = const Value.absent(),
                Value<String?> learningOrigin = const Value.absent(),
                required DateTime reviewedAt,
                Value<String?> clientRequestId = const Value.absent(),
                Value<BigInt> reviewVersion = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalReviewLogsCompanion.insert(
                id: id,
                userId: userId,
                cardId: cardId,
                rating: rating,
                stageBefore: stageBefore,
                stageAfter: stageAfter,
                isNewCard: isNewCard,
                learningOrigin: learningOrigin,
                reviewedAt: reviewedAt,
                clientRequestId: clientRequestId,
                reviewVersion: reviewVersion,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalReviewLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalReviewLogsTable,
      LocalReviewLog,
      $$LocalReviewLogsTableFilterComposer,
      $$LocalReviewLogsTableOrderingComposer,
      $$LocalReviewLogsTableAnnotationComposer,
      $$LocalReviewLogsTableCreateCompanionBuilder,
      $$LocalReviewLogsTableUpdateCompanionBuilder,
      (
        LocalReviewLog,
        BaseReferences<_$AppDatabase, $LocalReviewLogsTable, LocalReviewLog>,
      ),
      LocalReviewLog,
      PrefetchHooks Function()
    >;
typedef $$SyncMetaTableCreateCompanionBuilder =
    SyncMetaCompanion Function({
      required String userId,
      Value<String?> email,
      Value<String> refreshTime,
      Value<DateTime?> lastBootstrapAt,
      Value<int> clockOffsetMs,
      Value<BigInt> lastEventCursor,
      Value<int> rowid,
    });
typedef $$SyncMetaTableUpdateCompanionBuilder =
    SyncMetaCompanion Function({
      Value<String> userId,
      Value<String?> email,
      Value<String> refreshTime,
      Value<DateTime?> lastBootstrapAt,
      Value<int> clockOffsetMs,
      Value<BigInt> lastEventCursor,
      Value<int> rowid,
    });

class $$SyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refreshTime => $composableBuilder(
    column: $table.refreshTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastBootstrapAt => $composableBuilder(
    column: $table.lastBootstrapAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clockOffsetMs => $composableBuilder(
    column: $table.clockOffsetMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get lastEventCursor => $composableBuilder(
    column: $table.lastEventCursor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refreshTime => $composableBuilder(
    column: $table.refreshTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastBootstrapAt => $composableBuilder(
    column: $table.lastBootstrapAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clockOffsetMs => $composableBuilder(
    column: $table.clockOffsetMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get lastEventCursor => $composableBuilder(
    column: $table.lastEventCursor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get refreshTime => $composableBuilder(
    column: $table.refreshTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastBootstrapAt => $composableBuilder(
    column: $table.lastBootstrapAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get clockOffsetMs => $composableBuilder(
    column: $table.clockOffsetMs,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get lastEventCursor => $composableBuilder(
    column: $table.lastEventCursor,
    builder: (column) => column,
  );
}

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetaTable,
          SyncMetaData,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (
            SyncMetaData,
            BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>,
          ),
          SyncMetaData,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String> refreshTime = const Value.absent(),
                Value<DateTime?> lastBootstrapAt = const Value.absent(),
                Value<int> clockOffsetMs = const Value.absent(),
                Value<BigInt> lastEventCursor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion(
                userId: userId,
                email: email,
                refreshTime: refreshTime,
                lastBootstrapAt: lastBootstrapAt,
                clockOffsetMs: clockOffsetMs,
                lastEventCursor: lastEventCursor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<String?> email = const Value.absent(),
                Value<String> refreshTime = const Value.absent(),
                Value<DateTime?> lastBootstrapAt = const Value.absent(),
                Value<int> clockOffsetMs = const Value.absent(),
                Value<BigInt> lastEventCursor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion.insert(
                userId: userId,
                email: email,
                refreshTime: refreshTime,
                lastBootstrapAt: lastBootstrapAt,
                clockOffsetMs: clockOffsetMs,
                lastEventCursor: lastEventCursor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetaTable,
      SyncMetaData,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (
        SyncMetaData,
        BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>,
      ),
      SyncMetaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db, _db.localSettings);
  $$LocalDecksTableTableManager get localDecks =>
      $$LocalDecksTableTableManager(_db, _db.localDecks);
  $$LocalCardsTableTableManager get localCards =>
      $$LocalCardsTableTableManager(_db, _db.localCards);
  $$LocalReviewLogsTableTableManager get localReviewLogs =>
      $$LocalReviewLogsTableTableManager(_db, _db.localReviewLogs);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
}
