// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
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
  static const VerificationMeta _connectedAtMeta = const VerificationMeta(
    'connectedAt',
  );
  @override
  late final GeneratedColumn<int> connectedAt = GeneratedColumn<int>(
    'connected_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, provider, email, connectedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('connected_at')) {
      context.handle(
        _connectedAtMeta,
        connectedAt.isAcceptableOrUnknown(
          data['connected_at']!,
          _connectedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      connectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}connected_at'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String id;
  final String provider;
  final String email;
  final int connectedAt;
  const Account({
    required this.id,
    required this.provider,
    required this.email,
    required this.connectedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider'] = Variable<String>(provider);
    map['email'] = Variable<String>(email);
    map['connected_at'] = Variable<int>(connectedAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      provider: Value(provider),
      email: Value(email),
      connectedAt: Value(connectedAt),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      provider: serializer.fromJson<String>(json['provider']),
      email: serializer.fromJson<String>(json['email']),
      connectedAt: serializer.fromJson<int>(json['connectedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'provider': serializer.toJson<String>(provider),
      'email': serializer.toJson<String>(email),
      'connectedAt': serializer.toJson<int>(connectedAt),
    };
  }

  Account copyWith({
    String? id,
    String? provider,
    String? email,
    int? connectedAt,
  }) => Account(
    id: id ?? this.id,
    provider: provider ?? this.provider,
    email: email ?? this.email,
    connectedAt: connectedAt ?? this.connectedAt,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      provider: data.provider.present ? data.provider.value : this.provider,
      email: data.email.present ? data.email.value : this.email,
      connectedAt: data.connectedAt.present
          ? data.connectedAt.value
          : this.connectedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('email: $email, ')
          ..write('connectedAt: $connectedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, provider, email, connectedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.provider == this.provider &&
          other.email == this.email &&
          other.connectedAt == this.connectedAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<String> provider;
  final Value<String> email;
  final Value<int> connectedAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.provider = const Value.absent(),
    this.email = const Value.absent(),
    this.connectedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String provider,
    required String email,
    required int connectedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       provider = Value(provider),
       email = Value(email),
       connectedAt = Value(connectedAt);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<String>? provider,
    Expression<String>? email,
    Expression<int>? connectedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (provider != null) 'provider': provider,
      if (email != null) 'email': email,
      if (connectedAt != null) 'connected_at': connectedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? provider,
    Value<String>? email,
    Value<int>? connectedAt,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      email: email ?? this.email,
      connectedAt: connectedAt ?? this.connectedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (connectedAt.present) {
      map['connected_at'] = Variable<int>(connectedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('email: $email, ')
          ..write('connectedAt: $connectedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarsTable extends Calendars
    with TableInfo<$CalendarsTable, Calendar> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _googleCalendarIdMeta = const VerificationMeta(
    'googleCalendarId',
  );
  @override
  late final GeneratedColumn<String> googleCalendarId = GeneratedColumn<String>(
    'google_calendar_id',
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
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isVisibleMeta = const VerificationMeta(
    'isVisible',
  );
  @override
  late final GeneratedColumn<bool> isVisible = GeneratedColumn<bool>(
    'is_visible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_visible" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _accessRoleMeta = const VerificationMeta(
    'accessRole',
  );
  @override
  late final GeneratedColumn<String> accessRole = GeneratedColumn<String>(
    'access_role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncTokenMeta = const VerificationMeta(
    'syncToken',
  );
  @override
  late final GeneratedColumn<String> syncToken = GeneratedColumn<String>(
    'sync_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    googleCalendarId,
    name,
    color,
    isVisible,
    isDefault,
    accessRole,
    syncToken,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendars';
  @override
  VerificationContext validateIntegrity(
    Insertable<Calendar> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('google_calendar_id')) {
      context.handle(
        _googleCalendarIdMeta,
        googleCalendarId.isAcceptableOrUnknown(
          data['google_calendar_id']!,
          _googleCalendarIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_googleCalendarIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('is_visible')) {
      context.handle(
        _isVisibleMeta,
        isVisible.isAcceptableOrUnknown(data['is_visible']!, _isVisibleMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('access_role')) {
      context.handle(
        _accessRoleMeta,
        accessRole.isAcceptableOrUnknown(data['access_role']!, _accessRoleMeta),
      );
    } else if (isInserting) {
      context.missing(_accessRoleMeta);
    }
    if (data.containsKey('sync_token')) {
      context.handle(
        _syncTokenMeta,
        syncToken.isAcceptableOrUnknown(data['sync_token']!, _syncTokenMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Calendar map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Calendar(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      googleCalendarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}google_calendar_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      isVisible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_visible'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      accessRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_role'],
      )!,
      syncToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_token'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $CalendarsTable createAlias(String alias) {
    return $CalendarsTable(attachedDatabase, alias);
  }
}

class Calendar extends DataClass implements Insertable<Calendar> {
  final String id;
  final String accountId;
  final String googleCalendarId;
  final String name;
  final String? color;
  final bool isVisible;
  final bool isDefault;

  /// owner | writer | reader
  final String accessRole;
  final String? syncToken;
  final int? lastSyncedAt;
  const Calendar({
    required this.id,
    required this.accountId,
    required this.googleCalendarId,
    required this.name,
    this.color,
    required this.isVisible,
    required this.isDefault,
    required this.accessRole,
    this.syncToken,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['google_calendar_id'] = Variable<String>(googleCalendarId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['is_visible'] = Variable<bool>(isVisible);
    map['is_default'] = Variable<bool>(isDefault);
    map['access_role'] = Variable<String>(accessRole);
    if (!nullToAbsent || syncToken != null) {
      map['sync_token'] = Variable<String>(syncToken);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    return map;
  }

  CalendarsCompanion toCompanion(bool nullToAbsent) {
    return CalendarsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      googleCalendarId: Value(googleCalendarId),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      isVisible: Value(isVisible),
      isDefault: Value(isDefault),
      accessRole: Value(accessRole),
      syncToken: syncToken == null && nullToAbsent
          ? const Value.absent()
          : Value(syncToken),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory Calendar.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Calendar(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      googleCalendarId: serializer.fromJson<String>(json['googleCalendarId']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      isVisible: serializer.fromJson<bool>(json['isVisible']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      accessRole: serializer.fromJson<String>(json['accessRole']),
      syncToken: serializer.fromJson<String?>(json['syncToken']),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'googleCalendarId': serializer.toJson<String>(googleCalendarId),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'isVisible': serializer.toJson<bool>(isVisible),
      'isDefault': serializer.toJson<bool>(isDefault),
      'accessRole': serializer.toJson<String>(accessRole),
      'syncToken': serializer.toJson<String?>(syncToken),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
    };
  }

  Calendar copyWith({
    String? id,
    String? accountId,
    String? googleCalendarId,
    String? name,
    Value<String?> color = const Value.absent(),
    bool? isVisible,
    bool? isDefault,
    String? accessRole,
    Value<String?> syncToken = const Value.absent(),
    Value<int?> lastSyncedAt = const Value.absent(),
  }) => Calendar(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    googleCalendarId: googleCalendarId ?? this.googleCalendarId,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    isVisible: isVisible ?? this.isVisible,
    isDefault: isDefault ?? this.isDefault,
    accessRole: accessRole ?? this.accessRole,
    syncToken: syncToken.present ? syncToken.value : this.syncToken,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  Calendar copyWithCompanion(CalendarsCompanion data) {
    return Calendar(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      googleCalendarId: data.googleCalendarId.present
          ? data.googleCalendarId.value
          : this.googleCalendarId,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      isVisible: data.isVisible.present ? data.isVisible.value : this.isVisible,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      accessRole: data.accessRole.present
          ? data.accessRole.value
          : this.accessRole,
      syncToken: data.syncToken.present ? data.syncToken.value : this.syncToken,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Calendar(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('googleCalendarId: $googleCalendarId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('isVisible: $isVisible, ')
          ..write('isDefault: $isDefault, ')
          ..write('accessRole: $accessRole, ')
          ..write('syncToken: $syncToken, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    googleCalendarId,
    name,
    color,
    isVisible,
    isDefault,
    accessRole,
    syncToken,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Calendar &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.googleCalendarId == this.googleCalendarId &&
          other.name == this.name &&
          other.color == this.color &&
          other.isVisible == this.isVisible &&
          other.isDefault == this.isDefault &&
          other.accessRole == this.accessRole &&
          other.syncToken == this.syncToken &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class CalendarsCompanion extends UpdateCompanion<Calendar> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> googleCalendarId;
  final Value<String> name;
  final Value<String?> color;
  final Value<bool> isVisible;
  final Value<bool> isDefault;
  final Value<String> accessRole;
  final Value<String?> syncToken;
  final Value<int?> lastSyncedAt;
  final Value<int> rowid;
  const CalendarsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.googleCalendarId = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.isVisible = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.accessRole = const Value.absent(),
    this.syncToken = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarsCompanion.insert({
    required String id,
    required String accountId,
    required String googleCalendarId,
    required String name,
    this.color = const Value.absent(),
    this.isVisible = const Value.absent(),
    this.isDefault = const Value.absent(),
    required String accessRole,
    this.syncToken = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       googleCalendarId = Value(googleCalendarId),
       name = Value(name),
       accessRole = Value(accessRole);
  static Insertable<Calendar> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? googleCalendarId,
    Expression<String>? name,
    Expression<String>? color,
    Expression<bool>? isVisible,
    Expression<bool>? isDefault,
    Expression<String>? accessRole,
    Expression<String>? syncToken,
    Expression<int>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (googleCalendarId != null) 'google_calendar_id': googleCalendarId,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (isVisible != null) 'is_visible': isVisible,
      if (isDefault != null) 'is_default': isDefault,
      if (accessRole != null) 'access_role': accessRole,
      if (syncToken != null) 'sync_token': syncToken,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? googleCalendarId,
    Value<String>? name,
    Value<String?>? color,
    Value<bool>? isVisible,
    Value<bool>? isDefault,
    Value<String>? accessRole,
    Value<String?>? syncToken,
    Value<int?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return CalendarsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      googleCalendarId: googleCalendarId ?? this.googleCalendarId,
      name: name ?? this.name,
      color: color ?? this.color,
      isVisible: isVisible ?? this.isVisible,
      isDefault: isDefault ?? this.isDefault,
      accessRole: accessRole ?? this.accessRole,
      syncToken: syncToken ?? this.syncToken,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (googleCalendarId.present) {
      map['google_calendar_id'] = Variable<String>(googleCalendarId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (isVisible.present) {
      map['is_visible'] = Variable<bool>(isVisible.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (accessRole.present) {
      map['access_role'] = Variable<String>(accessRole.value);
    }
    if (syncToken.present) {
      map['sync_token'] = Variable<String>(syncToken.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('googleCalendarId: $googleCalendarId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('isVisible: $isVisible, ')
          ..write('isDefault: $isDefault, ')
          ..write('accessRole: $accessRole, ')
          ..write('syncToken: $syncToken, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allDayMeta = const VerificationMeta('allDay');
  @override
  late final GeneratedColumn<bool> allDay = GeneratedColumn<bool>(
    'all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("all_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<int> startAt = GeneratedColumn<int>(
    'start_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<int> endAt = GeneratedColumn<int>(
    'end_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doneAtMeta = const VerificationMeta('doneAt');
  @override
  late final GeneratedColumn<int> doneAt = GeneratedColumn<int>(
    'done_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rolledCountMeta = const VerificationMeta(
    'rolledCount',
  );
  @override
  late final GeneratedColumn<int> rolledCount = GeneratedColumn<int>(
    'rolled_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lifecycleAnchorDateMeta =
      const VerificationMeta('lifecycleAnchorDate');
  @override
  late final GeneratedColumn<String> lifecycleAnchorDate =
      GeneratedColumn<String>(
        'lifecycle_anchor_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta(
    'snoozedUntil',
  );
  @override
  late final GeneratedColumn<int> snoozedUntil = GeneratedColumn<int>(
    'snoozed_until',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rruleMeta = const VerificationMeta('rrule');
  @override
  late final GeneratedColumn<String> rrule = GeneratedColumn<String>(
    'rrule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calendarIdMeta = const VerificationMeta(
    'calendarId',
  );
  @override
  late final GeneratedColumn<String> calendarId = GeneratedColumn<String>(
    'calendar_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES calendars (id)',
    ),
  );
  static const VerificationMeta _googleEventIdMeta = const VerificationMeta(
    'googleEventId',
  );
  @override
  late final GeneratedColumn<String> googleEventId = GeneratedColumn<String>(
    'google_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _googleEtagMeta = const VerificationMeta(
    'googleEtag',
  );
  @override
  late final GeneratedColumn<String> googleEtag = GeneratedColumn<String>(
    'google_etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteUpdatedAtMeta = const VerificationMeta(
    'remoteUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> remoteUpdatedAt = GeneratedColumn<int>(
    'remote_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    title,
    notes,
    allDay,
    startAt,
    endAt,
    date,
    timezone,
    doneAt,
    priority,
    color,
    rolledCount,
    lifecycleAnchorDate,
    snoozedUntil,
    rrule,
    calendarId,
    googleEventId,
    googleEtag,
    remoteUpdatedAt,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<Item> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('all_day')) {
      context.handle(
        _allDayMeta,
        allDay.isAcceptableOrUnknown(data['all_day']!, _allDayMeta),
      );
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    }
    if (data.containsKey('end_at')) {
      context.handle(
        _endAtMeta,
        endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    }
    if (data.containsKey('done_at')) {
      context.handle(
        _doneAtMeta,
        doneAt.isAcceptableOrUnknown(data['done_at']!, _doneAtMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('rolled_count')) {
      context.handle(
        _rolledCountMeta,
        rolledCount.isAcceptableOrUnknown(
          data['rolled_count']!,
          _rolledCountMeta,
        ),
      );
    }
    if (data.containsKey('lifecycle_anchor_date')) {
      context.handle(
        _lifecycleAnchorDateMeta,
        lifecycleAnchorDate.isAcceptableOrUnknown(
          data['lifecycle_anchor_date']!,
          _lifecycleAnchorDateMeta,
        ),
      );
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
        _snoozedUntilMeta,
        snoozedUntil.isAcceptableOrUnknown(
          data['snoozed_until']!,
          _snoozedUntilMeta,
        ),
      );
    }
    if (data.containsKey('rrule')) {
      context.handle(
        _rruleMeta,
        rrule.isAcceptableOrUnknown(data['rrule']!, _rruleMeta),
      );
    }
    if (data.containsKey('calendar_id')) {
      context.handle(
        _calendarIdMeta,
        calendarId.isAcceptableOrUnknown(data['calendar_id']!, _calendarIdMeta),
      );
    }
    if (data.containsKey('google_event_id')) {
      context.handle(
        _googleEventIdMeta,
        googleEventId.isAcceptableOrUnknown(
          data['google_event_id']!,
          _googleEventIdMeta,
        ),
      );
    }
    if (data.containsKey('google_etag')) {
      context.handle(
        _googleEtagMeta,
        googleEtag.isAcceptableOrUnknown(data['google_etag']!, _googleEtagMeta),
      );
    }
    if (data.containsKey('remote_updated_at')) {
      context.handle(
        _remoteUpdatedAtMeta,
        remoteUpdatedAt.isAcceptableOrUnknown(
          data['remote_updated_at']!,
          _remoteUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      allDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}all_day'],
      )!,
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_at'],
      ),
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_at'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      ),
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      ),
      doneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}done_at'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      rolledCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rolled_count'],
      )!,
      lifecycleAnchorDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lifecycle_anchor_date'],
      ),
      snoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snoozed_until'],
      ),
      rrule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rrule'],
      ),
      calendarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar_id'],
      ),
      googleEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}google_event_id'],
      ),
      googleEtag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}google_etag'],
      ),
      remoteUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_updated_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class Item extends DataClass implements Insertable<Item> {
  /// uuid v7
  final String id;

  /// task | event
  final String kind;
  final String title;
  final String? notes;
  final bool allDay;

  /// UTC epoch ms
  final int? startAt;
  final int? endAt;

  /// YYYY-MM-DD, tüm gün girdiler ve saatsiz görevler için
  final String? date;
  final String? timezone;
  final int? doneAt;

  /// 0 normal, 1 önemli
  final int priority;
  final String? color;
  final int rolledCount;

  /// YYYY-MM-DD, görev ömrü sayacının başladığı gün
  final String? lifecycleAnchorDate;

  /// UTC epoch ms, “10 dk ertele” ile verilen yeni hatırlatma zamanı
  final int? snoozedUntil;

  /// RFC 5545 (P1)
  final String? rrule;
  final String? calendarId;
  final String? googleEventId;
  final String? googleEtag;
  final int? remoteUpdatedAt;
  final int createdAt;
  final int updatedAt;

  /// Yumuşak silme: çöp kutusundaki girdiler
  final int? deletedAt;
  const Item({
    required this.id,
    required this.kind,
    required this.title,
    this.notes,
    required this.allDay,
    this.startAt,
    this.endAt,
    this.date,
    this.timezone,
    this.doneAt,
    required this.priority,
    this.color,
    required this.rolledCount,
    this.lifecycleAnchorDate,
    this.snoozedUntil,
    this.rrule,
    this.calendarId,
    this.googleEventId,
    this.googleEtag,
    this.remoteUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['all_day'] = Variable<bool>(allDay);
    if (!nullToAbsent || startAt != null) {
      map['start_at'] = Variable<int>(startAt);
    }
    if (!nullToAbsent || endAt != null) {
      map['end_at'] = Variable<int>(endAt);
    }
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<String>(date);
    }
    if (!nullToAbsent || timezone != null) {
      map['timezone'] = Variable<String>(timezone);
    }
    if (!nullToAbsent || doneAt != null) {
      map['done_at'] = Variable<int>(doneAt);
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['rolled_count'] = Variable<int>(rolledCount);
    if (!nullToAbsent || lifecycleAnchorDate != null) {
      map['lifecycle_anchor_date'] = Variable<String>(lifecycleAnchorDate);
    }
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<int>(snoozedUntil);
    }
    if (!nullToAbsent || rrule != null) {
      map['rrule'] = Variable<String>(rrule);
    }
    if (!nullToAbsent || calendarId != null) {
      map['calendar_id'] = Variable<String>(calendarId);
    }
    if (!nullToAbsent || googleEventId != null) {
      map['google_event_id'] = Variable<String>(googleEventId);
    }
    if (!nullToAbsent || googleEtag != null) {
      map['google_etag'] = Variable<String>(googleEtag);
    }
    if (!nullToAbsent || remoteUpdatedAt != null) {
      map['remote_updated_at'] = Variable<int>(remoteUpdatedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      kind: Value(kind),
      title: Value(title),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      allDay: Value(allDay),
      startAt: startAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startAt),
      endAt: endAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endAt),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
      timezone: timezone == null && nullToAbsent
          ? const Value.absent()
          : Value(timezone),
      doneAt: doneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(doneAt),
      priority: Value(priority),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      rolledCount: Value(rolledCount),
      lifecycleAnchorDate: lifecycleAnchorDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lifecycleAnchorDate),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
      rrule: rrule == null && nullToAbsent
          ? const Value.absent()
          : Value(rrule),
      calendarId: calendarId == null && nullToAbsent
          ? const Value.absent()
          : Value(calendarId),
      googleEventId: googleEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(googleEventId),
      googleEtag: googleEtag == null && nullToAbsent
          ? const Value.absent()
          : Value(googleEtag),
      remoteUpdatedAt: remoteUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUpdatedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Item.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      allDay: serializer.fromJson<bool>(json['allDay']),
      startAt: serializer.fromJson<int?>(json['startAt']),
      endAt: serializer.fromJson<int?>(json['endAt']),
      date: serializer.fromJson<String?>(json['date']),
      timezone: serializer.fromJson<String?>(json['timezone']),
      doneAt: serializer.fromJson<int?>(json['doneAt']),
      priority: serializer.fromJson<int>(json['priority']),
      color: serializer.fromJson<String?>(json['color']),
      rolledCount: serializer.fromJson<int>(json['rolledCount']),
      lifecycleAnchorDate: serializer.fromJson<String?>(
        json['lifecycleAnchorDate'],
      ),
      snoozedUntil: serializer.fromJson<int?>(json['snoozedUntil']),
      rrule: serializer.fromJson<String?>(json['rrule']),
      calendarId: serializer.fromJson<String?>(json['calendarId']),
      googleEventId: serializer.fromJson<String?>(json['googleEventId']),
      googleEtag: serializer.fromJson<String?>(json['googleEtag']),
      remoteUpdatedAt: serializer.fromJson<int?>(json['remoteUpdatedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'allDay': serializer.toJson<bool>(allDay),
      'startAt': serializer.toJson<int?>(startAt),
      'endAt': serializer.toJson<int?>(endAt),
      'date': serializer.toJson<String?>(date),
      'timezone': serializer.toJson<String?>(timezone),
      'doneAt': serializer.toJson<int?>(doneAt),
      'priority': serializer.toJson<int>(priority),
      'color': serializer.toJson<String?>(color),
      'rolledCount': serializer.toJson<int>(rolledCount),
      'lifecycleAnchorDate': serializer.toJson<String?>(lifecycleAnchorDate),
      'snoozedUntil': serializer.toJson<int?>(snoozedUntil),
      'rrule': serializer.toJson<String?>(rrule),
      'calendarId': serializer.toJson<String?>(calendarId),
      'googleEventId': serializer.toJson<String?>(googleEventId),
      'googleEtag': serializer.toJson<String?>(googleEtag),
      'remoteUpdatedAt': serializer.toJson<int?>(remoteUpdatedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Item copyWith({
    String? id,
    String? kind,
    String? title,
    Value<String?> notes = const Value.absent(),
    bool? allDay,
    Value<int?> startAt = const Value.absent(),
    Value<int?> endAt = const Value.absent(),
    Value<String?> date = const Value.absent(),
    Value<String?> timezone = const Value.absent(),
    Value<int?> doneAt = const Value.absent(),
    int? priority,
    Value<String?> color = const Value.absent(),
    int? rolledCount,
    Value<String?> lifecycleAnchorDate = const Value.absent(),
    Value<int?> snoozedUntil = const Value.absent(),
    Value<String?> rrule = const Value.absent(),
    Value<String?> calendarId = const Value.absent(),
    Value<String?> googleEventId = const Value.absent(),
    Value<String?> googleEtag = const Value.absent(),
    Value<int?> remoteUpdatedAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => Item(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    notes: notes.present ? notes.value : this.notes,
    allDay: allDay ?? this.allDay,
    startAt: startAt.present ? startAt.value : this.startAt,
    endAt: endAt.present ? endAt.value : this.endAt,
    date: date.present ? date.value : this.date,
    timezone: timezone.present ? timezone.value : this.timezone,
    doneAt: doneAt.present ? doneAt.value : this.doneAt,
    priority: priority ?? this.priority,
    color: color.present ? color.value : this.color,
    rolledCount: rolledCount ?? this.rolledCount,
    lifecycleAnchorDate: lifecycleAnchorDate.present
        ? lifecycleAnchorDate.value
        : this.lifecycleAnchorDate,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    rrule: rrule.present ? rrule.value : this.rrule,
    calendarId: calendarId.present ? calendarId.value : this.calendarId,
    googleEventId: googleEventId.present
        ? googleEventId.value
        : this.googleEventId,
    googleEtag: googleEtag.present ? googleEtag.value : this.googleEtag,
    remoteUpdatedAt: remoteUpdatedAt.present
        ? remoteUpdatedAt.value
        : this.remoteUpdatedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      allDay: data.allDay.present ? data.allDay.value : this.allDay,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      date: data.date.present ? data.date.value : this.date,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      doneAt: data.doneAt.present ? data.doneAt.value : this.doneAt,
      priority: data.priority.present ? data.priority.value : this.priority,
      color: data.color.present ? data.color.value : this.color,
      rolledCount: data.rolledCount.present
          ? data.rolledCount.value
          : this.rolledCount,
      lifecycleAnchorDate: data.lifecycleAnchorDate.present
          ? data.lifecycleAnchorDate.value
          : this.lifecycleAnchorDate,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
      rrule: data.rrule.present ? data.rrule.value : this.rrule,
      calendarId: data.calendarId.present
          ? data.calendarId.value
          : this.calendarId,
      googleEventId: data.googleEventId.present
          ? data.googleEventId.value
          : this.googleEventId,
      googleEtag: data.googleEtag.present
          ? data.googleEtag.value
          : this.googleEtag,
      remoteUpdatedAt: data.remoteUpdatedAt.present
          ? data.remoteUpdatedAt.value
          : this.remoteUpdatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('allDay: $allDay, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('date: $date, ')
          ..write('timezone: $timezone, ')
          ..write('doneAt: $doneAt, ')
          ..write('priority: $priority, ')
          ..write('color: $color, ')
          ..write('rolledCount: $rolledCount, ')
          ..write('lifecycleAnchorDate: $lifecycleAnchorDate, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('rrule: $rrule, ')
          ..write('calendarId: $calendarId, ')
          ..write('googleEventId: $googleEventId, ')
          ..write('googleEtag: $googleEtag, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    kind,
    title,
    notes,
    allDay,
    startAt,
    endAt,
    date,
    timezone,
    doneAt,
    priority,
    color,
    rolledCount,
    lifecycleAnchorDate,
    snoozedUntil,
    rrule,
    calendarId,
    googleEventId,
    googleEtag,
    remoteUpdatedAt,
    createdAt,
    updatedAt,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.allDay == this.allDay &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.date == this.date &&
          other.timezone == this.timezone &&
          other.doneAt == this.doneAt &&
          other.priority == this.priority &&
          other.color == this.color &&
          other.rolledCount == this.rolledCount &&
          other.lifecycleAnchorDate == this.lifecycleAnchorDate &&
          other.snoozedUntil == this.snoozedUntil &&
          other.rrule == this.rrule &&
          other.calendarId == this.calendarId &&
          other.googleEventId == this.googleEventId &&
          other.googleEtag == this.googleEtag &&
          other.remoteUpdatedAt == this.remoteUpdatedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> title;
  final Value<String?> notes;
  final Value<bool> allDay;
  final Value<int?> startAt;
  final Value<int?> endAt;
  final Value<String?> date;
  final Value<String?> timezone;
  final Value<int?> doneAt;
  final Value<int> priority;
  final Value<String?> color;
  final Value<int> rolledCount;
  final Value<String?> lifecycleAnchorDate;
  final Value<int?> snoozedUntil;
  final Value<String?> rrule;
  final Value<String?> calendarId;
  final Value<String?> googleEventId;
  final Value<String?> googleEtag;
  final Value<int?> remoteUpdatedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.allDay = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.date = const Value.absent(),
    this.timezone = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.color = const Value.absent(),
    this.rolledCount = const Value.absent(),
    this.lifecycleAnchorDate = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.rrule = const Value.absent(),
    this.calendarId = const Value.absent(),
    this.googleEventId = const Value.absent(),
    this.googleEtag = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required String id,
    required String kind,
    required String title,
    this.notes = const Value.absent(),
    this.allDay = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.date = const Value.absent(),
    this.timezone = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.color = const Value.absent(),
    this.rolledCount = const Value.absent(),
    this.lifecycleAnchorDate = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.rrule = const Value.absent(),
    this.calendarId = const Value.absent(),
    this.googleEventId = const Value.absent(),
    this.googleEtag = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Item> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<bool>? allDay,
    Expression<int>? startAt,
    Expression<int>? endAt,
    Expression<String>? date,
    Expression<String>? timezone,
    Expression<int>? doneAt,
    Expression<int>? priority,
    Expression<String>? color,
    Expression<int>? rolledCount,
    Expression<String>? lifecycleAnchorDate,
    Expression<int>? snoozedUntil,
    Expression<String>? rrule,
    Expression<String>? calendarId,
    Expression<String>? googleEventId,
    Expression<String>? googleEtag,
    Expression<int>? remoteUpdatedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (allDay != null) 'all_day': allDay,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (date != null) 'date': date,
      if (timezone != null) 'timezone': timezone,
      if (doneAt != null) 'done_at': doneAt,
      if (priority != null) 'priority': priority,
      if (color != null) 'color': color,
      if (rolledCount != null) 'rolled_count': rolledCount,
      if (lifecycleAnchorDate != null)
        'lifecycle_anchor_date': lifecycleAnchorDate,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (rrule != null) 'rrule': rrule,
      if (calendarId != null) 'calendar_id': calendarId,
      if (googleEventId != null) 'google_event_id': googleEventId,
      if (googleEtag != null) 'google_etag': googleEtag,
      if (remoteUpdatedAt != null) 'remote_updated_at': remoteUpdatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? title,
    Value<String?>? notes,
    Value<bool>? allDay,
    Value<int?>? startAt,
    Value<int?>? endAt,
    Value<String?>? date,
    Value<String?>? timezone,
    Value<int?>? doneAt,
    Value<int>? priority,
    Value<String?>? color,
    Value<int>? rolledCount,
    Value<String?>? lifecycleAnchorDate,
    Value<int?>? snoozedUntil,
    Value<String?>? rrule,
    Value<String?>? calendarId,
    Value<String?>? googleEventId,
    Value<String?>? googleEtag,
    Value<int?>? remoteUpdatedAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      allDay: allDay ?? this.allDay,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      date: date ?? this.date,
      timezone: timezone ?? this.timezone,
      doneAt: doneAt ?? this.doneAt,
      priority: priority ?? this.priority,
      color: color ?? this.color,
      rolledCount: rolledCount ?? this.rolledCount,
      lifecycleAnchorDate: lifecycleAnchorDate ?? this.lifecycleAnchorDate,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      rrule: rrule ?? this.rrule,
      calendarId: calendarId ?? this.calendarId,
      googleEventId: googleEventId ?? this.googleEventId,
      googleEtag: googleEtag ?? this.googleEtag,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (allDay.present) {
      map['all_day'] = Variable<bool>(allDay.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<int>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<int>(endAt.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (doneAt.present) {
      map['done_at'] = Variable<int>(doneAt.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (rolledCount.present) {
      map['rolled_count'] = Variable<int>(rolledCount.value);
    }
    if (lifecycleAnchorDate.present) {
      map['lifecycle_anchor_date'] = Variable<String>(
        lifecycleAnchorDate.value,
      );
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<int>(snoozedUntil.value);
    }
    if (rrule.present) {
      map['rrule'] = Variable<String>(rrule.value);
    }
    if (calendarId.present) {
      map['calendar_id'] = Variable<String>(calendarId.value);
    }
    if (googleEventId.present) {
      map['google_event_id'] = Variable<String>(googleEventId.value);
    }
    if (googleEtag.present) {
      map['google_etag'] = Variable<String>(googleEtag.value);
    }
    if (remoteUpdatedAt.present) {
      map['remote_updated_at'] = Variable<int>(remoteUpdatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('allDay: $allDay, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('date: $date, ')
          ..write('timezone: $timezone, ')
          ..write('doneAt: $doneAt, ')
          ..write('priority: $priority, ')
          ..write('color: $color, ')
          ..write('rolledCount: $rolledCount, ')
          ..write('lifecycleAnchorDate: $lifecycleAnchorDate, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('rrule: $rrule, ')
          ..write('calendarId: $calendarId, ')
          ..write('googleEventId: $googleEventId, ')
          ..write('googleEtag: $googleEtag, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _offsetMinMeta = const VerificationMeta(
    'offsetMin',
  );
  @override
  late final GeneratedColumn<int> offsetMin = GeneratedColumn<int>(
    'offset_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _osNotificationIdMeta = const VerificationMeta(
    'osNotificationId',
  );
  @override
  late final GeneratedColumn<String> osNotificationId = GeneratedColumn<String>(
    'os_notification_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    offsetMin,
    osNotificationId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('offset_min')) {
      context.handle(
        _offsetMinMeta,
        offsetMin.isAcceptableOrUnknown(data['offset_min']!, _offsetMinMeta),
      );
    } else if (isInserting) {
      context.missing(_offsetMinMeta);
    }
    if (data.containsKey('os_notification_id')) {
      context.handle(
        _osNotificationIdMeta,
        osNotificationId.isAcceptableOrUnknown(
          data['os_notification_id']!,
          _osNotificationIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      offsetMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_min'],
      )!,
      osNotificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}os_notification_id'],
      ),
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final String id;
  final String itemId;
  final int offsetMin;
  final String? osNotificationId;
  const Reminder({
    required this.id,
    required this.itemId,
    required this.offsetMin,
    this.osNotificationId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['offset_min'] = Variable<int>(offsetMin);
    if (!nullToAbsent || osNotificationId != null) {
      map['os_notification_id'] = Variable<String>(osNotificationId);
    }
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      itemId: Value(itemId),
      offsetMin: Value(offsetMin),
      osNotificationId: osNotificationId == null && nullToAbsent
          ? const Value.absent()
          : Value(osNotificationId),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      offsetMin: serializer.fromJson<int>(json['offsetMin']),
      osNotificationId: serializer.fromJson<String?>(json['osNotificationId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'offsetMin': serializer.toJson<int>(offsetMin),
      'osNotificationId': serializer.toJson<String?>(osNotificationId),
    };
  }

  Reminder copyWith({
    String? id,
    String? itemId,
    int? offsetMin,
    Value<String?> osNotificationId = const Value.absent(),
  }) => Reminder(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    offsetMin: offsetMin ?? this.offsetMin,
    osNotificationId: osNotificationId.present
        ? osNotificationId.value
        : this.osNotificationId,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      offsetMin: data.offsetMin.present ? data.offsetMin.value : this.offsetMin,
      osNotificationId: data.osNotificationId.present
          ? data.osNotificationId.value
          : this.osNotificationId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('offsetMin: $offsetMin, ')
          ..write('osNotificationId: $osNotificationId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itemId, offsetMin, osNotificationId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.offsetMin == this.offsetMin &&
          other.osNotificationId == this.osNotificationId);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<int> offsetMin;
  final Value<String?> osNotificationId;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.offsetMin = const Value.absent(),
    this.osNotificationId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required String itemId,
    required int offsetMin,
    this.osNotificationId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       offsetMin = Value(offsetMin);
  static Insertable<Reminder> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<int>? offsetMin,
    Expression<String>? osNotificationId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (offsetMin != null) 'offset_min': offsetMin,
      if (osNotificationId != null) 'os_notification_id': osNotificationId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<int>? offsetMin,
    Value<String?>? osNotificationId,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      offsetMin: offsetMin ?? this.offsetMin,
      osNotificationId: osNotificationId ?? this.osNotificationId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (offsetMin.present) {
      map['offset_min'] = Variable<int>(offsetMin.value);
    }
    if (osNotificationId.present) {
      map['os_notification_id'] = Variable<String>(osNotificationId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('offsetMin: $offsetMin, ')
          ..write('osNotificationId: $osNotificationId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextTryAtMeta = const VerificationMeta(
    'nextTryAt',
  );
  @override
  late final GeneratedColumn<int> nextTryAt = GeneratedColumn<int>(
    'next_try_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    op,
    payloadJson,
    attempts,
    nextTryAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_try_at')) {
      context.handle(
        _nextTryAtMeta,
        nextTryAt.isAcceptableOrUnknown(data['next_try_at']!, _nextTryAtMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextTryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_try_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueEntry extends DataClass implements Insertable<SyncQueueEntry> {
  final int id;
  final String itemId;

  /// create | update | delete
  final String op;
  final String payloadJson;
  final int attempts;
  final int? nextTryAt;
  final String? lastError;
  const SyncQueueEntry({
    required this.id,
    required this.itemId,
    required this.op,
    required this.payloadJson,
    required this.attempts,
    this.nextTryAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<String>(itemId);
    map['op'] = Variable<String>(op);
    map['payload_json'] = Variable<String>(payloadJson);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextTryAt != null) {
      map['next_try_at'] = Variable<int>(nextTryAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      itemId: Value(itemId),
      op: Value(op),
      payloadJson: Value(payloadJson),
      attempts: Value(attempts),
      nextTryAt: nextTryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextTryAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntry(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      op: serializer.fromJson<String>(json['op']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextTryAt: serializer.fromJson<int?>(json['nextTryAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<String>(itemId),
      'op': serializer.toJson<String>(op),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'attempts': serializer.toJson<int>(attempts),
      'nextTryAt': serializer.toJson<int?>(nextTryAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueueEntry copyWith({
    int? id,
    String? itemId,
    String? op,
    String? payloadJson,
    int? attempts,
    Value<int?> nextTryAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => SyncQueueEntry(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    op: op ?? this.op,
    payloadJson: payloadJson ?? this.payloadJson,
    attempts: attempts ?? this.attempts,
    nextTryAt: nextTryAt.present ? nextTryAt.value : this.nextTryAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncQueueEntry copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      op: data.op.present ? data.op.value : this.op,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextTryAt: data.nextTryAt.present ? data.nextTryAt.value : this.nextTryAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntry(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('op: $op, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('attempts: $attempts, ')
          ..write('nextTryAt: $nextTryAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, itemId, op, payloadJson, attempts, nextTryAt, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntry &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.op == this.op &&
          other.payloadJson == this.payloadJson &&
          other.attempts == this.attempts &&
          other.nextTryAt == this.nextTryAt &&
          other.lastError == this.lastError);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueEntry> {
  final Value<int> id;
  final Value<String> itemId;
  final Value<String> op;
  final Value<String> payloadJson;
  final Value<int> attempts;
  final Value<int?> nextTryAt;
  final Value<String?> lastError;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.op = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextTryAt = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String itemId,
    required String op,
    required String payloadJson,
    this.attempts = const Value.absent(),
    this.nextTryAt = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : itemId = Value(itemId),
       op = Value(op),
       payloadJson = Value(payloadJson);
  static Insertable<SyncQueueEntry> custom({
    Expression<int>? id,
    Expression<String>? itemId,
    Expression<String>? op,
    Expression<String>? payloadJson,
    Expression<int>? attempts,
    Expression<int>? nextTryAt,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (op != null) 'op': op,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (attempts != null) 'attempts': attempts,
      if (nextTryAt != null) 'next_try_at': nextTryAt,
      if (lastError != null) 'last_error': lastError,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? itemId,
    Value<String>? op,
    Value<String>? payloadJson,
    Value<int>? attempts,
    Value<int?>? nextTryAt,
    Value<String?>? lastError,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      op: op ?? this.op,
      payloadJson: payloadJson ?? this.payloadJson,
      attempts: attempts ?? this.attempts,
      nextTryAt: nextTryAt ?? this.nextTryAt,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextTryAt.present) {
      map['next_try_at'] = Variable<int>(nextTryAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('op: $op, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('attempts: $attempts, ')
          ..write('nextTryAt: $nextTryAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CalendarsTable calendars = $CalendarsTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index itemsDate = Index(
    'items_date',
    'CREATE INDEX items_date ON items (date)',
  );
  late final Index itemsStartAt = Index(
    'items_start_at',
    'CREATE INDEX items_start_at ON items (start_at)',
  );
  late final Index itemsGoogleEventId = Index(
    'items_google_event_id',
    'CREATE INDEX items_google_event_id ON items (google_event_id)',
  );
  late final Index itemsUpdatedAt = Index(
    'items_updated_at',
    'CREATE INDEX items_updated_at ON items (updated_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    calendars,
    items,
    reminders,
    syncQueue,
    settings,
    itemsDate,
    itemsStartAt,
    itemsGoogleEventId,
    itemsUpdatedAt,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String provider,
  required String email,
  required int connectedAt,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> provider,
  Value<String> email,
  Value<int> connectedAt,
  Value<int> rowid,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CalendarsTable, List<Calendar>>
  _calendarsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.calendars,
    aliasName: 'accounts__id__calendars__account_id',
  );

  $$CalendarsTableProcessedTableManager get calendarsRefs {
    final manager = $$CalendarsTableTableManager(
      $_db,
      $_db.calendars,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_calendarsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
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

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get connectedAt => $composableBuilder(
    column: $table.connectedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> calendarsRefs(
    Expression<bool> Function($$CalendarsTableFilterComposer f) f,
  ) {
    final $$CalendarsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableFilterComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
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

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get connectedAt => $composableBuilder(
    column: $table.connectedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<int> get connectedAt => $composableBuilder(
    column: $table.connectedAt,
    builder: (column) => column,
  );

  Expression<T> calendarsRefs<T extends Object>(
    Expression<T> Function($$CalendarsTableAnnotationComposer a) f,
  ) {
    final $$CalendarsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableAnnotationComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({bool calendarsRefs})
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<int> connectedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                provider: provider,
                email: email,
                connectedAt: connectedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String provider,
                required String email,
                required int connectedAt,
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                provider: provider,
                email: email,
                connectedAt: connectedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, Account>(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({calendarsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (calendarsRefs) db.calendars],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (calendarsRefs)
                    await $_getPrefetchedDataByColumns<
                      Account,
                      $AccountsTable,
                      Calendar,
                      $CalendarsTable
                    >(
                      currentTable: table,
                      referencedTable: $$AccountsTableReferences
                          ._calendarsRefsTable(db),
                      managerFromTypedResult: (p0) => $$AccountsTableReferences(
                        db,
                        table,
                        p0,
                      ).calendarsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'account_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({bool calendarsRefs})
    >;
typedef $$CalendarsTableCreateCompanionBuilder = CalendarsCompanion Function({
  required String id,
  required String accountId,
  required String googleCalendarId,
  required String name,
  Value<String?> color,
  Value<bool> isVisible,
  Value<bool> isDefault,
  required String accessRole,
  Value<String?> syncToken,
  Value<int?> lastSyncedAt,
  Value<int> rowid,
});
typedef $$CalendarsTableUpdateCompanionBuilder = CalendarsCompanion Function({
  Value<String> id,
  Value<String> accountId,
  Value<String> googleCalendarId,
  Value<String> name,
  Value<String?> color,
  Value<bool> isVisible,
  Value<bool> isDefault,
  Value<String> accessRole,
  Value<String?> syncToken,
  Value<int?> lastSyncedAt,
  Value<int> rowid,
});

final class $$CalendarsTableReferences
    extends BaseReferences<_$AppDatabase, $CalendarsTable, Calendar> {
  $$CalendarsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('calendars__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ItemsTable, List<Item>> _itemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.items,
    aliasName: 'calendars__id__items__calendar_id',
  );

  $$ItemsTableProcessedTableManager get itemsRefs {
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.calendarId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CalendarsTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarsTable> {
  $$CalendarsTableFilterComposer({
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

  ColumnFilters<String> get googleCalendarId => $composableBuilder(
    column: $table.googleCalendarId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVisible => $composableBuilder(
    column: $table.isVisible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessRole => $composableBuilder(
    column: $table.accessRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncToken => $composableBuilder(
    column: $table.syncToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> itemsRefs(
    Expression<bool> Function($$ItemsTableFilterComposer f) f,
  ) {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.calendarId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CalendarsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarsTable> {
  $$CalendarsTableOrderingComposer({
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

  ColumnOrderings<String> get googleCalendarId => $composableBuilder(
    column: $table.googleCalendarId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVisible => $composableBuilder(
    column: $table.isVisible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessRole => $composableBuilder(
    column: $table.accessRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncToken => $composableBuilder(
    column: $table.syncToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarsTable> {
  $$CalendarsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get googleCalendarId => $composableBuilder(
    column: $table.googleCalendarId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get isVisible =>
      $composableBuilder(column: $table.isVisible, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<String> get accessRole => $composableBuilder(
    column: $table.accessRole,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncToken =>
      $composableBuilder(column: $table.syncToken, builder: (column) => column);

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> itemsRefs<T extends Object>(
    Expression<T> Function($$ItemsTableAnnotationComposer a) f,
  ) {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.calendarId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CalendarsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarsTable,
          Calendar,
          $$CalendarsTableFilterComposer,
          $$CalendarsTableOrderingComposer,
          $$CalendarsTableAnnotationComposer,
          $$CalendarsTableCreateCompanionBuilder,
          $$CalendarsTableUpdateCompanionBuilder,
          (Calendar, $$CalendarsTableReferences),
          Calendar,
          PrefetchHooks Function({bool accountId, bool itemsRefs})
        > {
  $$CalendarsTableTableManager(_$AppDatabase db, $CalendarsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> googleCalendarId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<bool> isVisible = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<String> accessRole = const Value.absent(),
                Value<String?> syncToken = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarsCompanion(
                id: id,
                accountId: accountId,
                googleCalendarId: googleCalendarId,
                name: name,
                color: color,
                isVisible: isVisible,
                isDefault: isDefault,
                accessRole: accessRole,
                syncToken: syncToken,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String googleCalendarId,
                required String name,
                Value<String?> color = const Value.absent(),
                Value<bool> isVisible = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                required String accessRole,
                Value<String?> syncToken = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarsCompanion.insert(
                id: id,
                accountId: accountId,
                googleCalendarId: googleCalendarId,
                name: name,
                color: color,
                isVisible: isVisible,
                isDefault: isDefault,
                accessRole: accessRole,
                syncToken: syncToken,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CalendarsTable, Calendar>(table),
                  $$CalendarsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false, itemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (itemsRefs) db.items],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$CalendarsTableReferences
                            ._accountIdTable(db),
                        referencedColumn: $$CalendarsTableReferences
                            ._accountIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itemsRefs)
                    await $_getPrefetchedDataByColumns<
                      Calendar,
                      $CalendarsTable,
                      Item,
                      $ItemsTable
                    >(
                      currentTable: table,
                      referencedTable: $$CalendarsTableReferences
                          ._itemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CalendarsTableReferences(db, table, p0).itemsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'calendar_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CalendarsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarsTable,
      Calendar,
      $$CalendarsTableFilterComposer,
      $$CalendarsTableOrderingComposer,
      $$CalendarsTableAnnotationComposer,
      $$CalendarsTableCreateCompanionBuilder,
      $$CalendarsTableUpdateCompanionBuilder,
      (Calendar, $$CalendarsTableReferences),
      Calendar,
      PrefetchHooks Function({bool accountId, bool itemsRefs})
    >;
typedef $$ItemsTableCreateCompanionBuilder = ItemsCompanion Function({
  required String id,
  required String kind,
  required String title,
  Value<String?> notes,
  Value<bool> allDay,
  Value<int?> startAt,
  Value<int?> endAt,
  Value<String?> date,
  Value<String?> timezone,
  Value<int?> doneAt,
  Value<int> priority,
  Value<String?> color,
  Value<int> rolledCount,
  Value<String?> lifecycleAnchorDate,
  Value<int?> snoozedUntil,
  Value<String?> rrule,
  Value<String?> calendarId,
  Value<String?> googleEventId,
  Value<String?> googleEtag,
  Value<int?> remoteUpdatedAt,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({
  Value<String> id,
  Value<String> kind,
  Value<String> title,
  Value<String?> notes,
  Value<bool> allDay,
  Value<int?> startAt,
  Value<int?> endAt,
  Value<String?> date,
  Value<String?> timezone,
  Value<int?> doneAt,
  Value<int> priority,
  Value<String?> color,
  Value<int> rolledCount,
  Value<String?> lifecycleAnchorDate,
  Value<int?> snoozedUntil,
  Value<String?> rrule,
  Value<String?> calendarId,
  Value<String?> googleEventId,
  Value<String?> googleEtag,
  Value<int?> remoteUpdatedAt,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $$ItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsTable, Item> {
  $$ItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CalendarsTable _calendarIdTable(_$AppDatabase db) =>
      db.calendars.createAlias('items__calendar_id__calendars__id');

  $$CalendarsTableProcessedTableManager? get calendarId {
    final $_column = $_itemColumn<String>('calendar_id');
    if ($_column == null) return null;
    final manager = $$CalendarsTableTableManager(
      $_db,
      $_db.calendars,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_calendarIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RemindersTable, List<Reminder>>
  _remindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminders,
    aliasName: 'items__id__reminders__item_id',
  );

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager(
      $_db,
      $_db.reminders,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rolledCount => $composableBuilder(
    column: $table.rolledCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lifecycleAnchorDate => $composableBuilder(
    column: $table.lifecycleAnchorDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get googleEventId => $composableBuilder(
    column: $table.googleEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get googleEtag => $composableBuilder(
    column: $table.googleEtag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CalendarsTableFilterComposer get calendarId {
    final $$CalendarsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableFilterComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> remindersRefs(
    Expression<bool> Function($$RemindersTableFilterComposer f) f,
  ) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rolledCount => $composableBuilder(
    column: $table.rolledCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lifecycleAnchorDate => $composableBuilder(
    column: $table.lifecycleAnchorDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get googleEventId => $composableBuilder(
    column: $table.googleEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get googleEtag => $composableBuilder(
    column: $table.googleEtag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CalendarsTableOrderingComposer get calendarId {
    final $$CalendarsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableOrderingComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get allDay =>
      $composableBuilder(column: $table.allDay, builder: (column) => column);

  GeneratedColumn<int> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<int> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<int> get doneAt =>
      $composableBuilder(column: $table.doneAt, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get rolledCount => $composableBuilder(
    column: $table.rolledCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lifecycleAnchorDate => $composableBuilder(
    column: $table.lifecycleAnchorDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rrule =>
      $composableBuilder(column: $table.rrule, builder: (column) => column);

  GeneratedColumn<String> get googleEventId => $composableBuilder(
    column: $table.googleEventId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get googleEtag => $composableBuilder(
    column: $table.googleEtag,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$CalendarsTableAnnotationComposer get calendarId {
    final $$CalendarsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableAnnotationComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> remindersRefs<T extends Object>(
    Expression<T> Function($$RemindersTableAnnotationComposer a) f,
  ) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          Item,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (Item, $$ItemsTableReferences),
          Item,
          PrefetchHooks Function({bool calendarId, bool remindersRefs})
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> allDay = const Value.absent(),
                Value<int?> startAt = const Value.absent(),
                Value<int?> endAt = const Value.absent(),
                Value<String?> date = const Value.absent(),
                Value<String?> timezone = const Value.absent(),
                Value<int?> doneAt = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> rolledCount = const Value.absent(),
                Value<String?> lifecycleAnchorDate = const Value.absent(),
                Value<int?> snoozedUntil = const Value.absent(),
                Value<String?> rrule = const Value.absent(),
                Value<String?> calendarId = const Value.absent(),
                Value<String?> googleEventId = const Value.absent(),
                Value<String?> googleEtag = const Value.absent(),
                Value<int?> remoteUpdatedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                kind: kind,
                title: title,
                notes: notes,
                allDay: allDay,
                startAt: startAt,
                endAt: endAt,
                date: date,
                timezone: timezone,
                doneAt: doneAt,
                priority: priority,
                color: color,
                rolledCount: rolledCount,
                lifecycleAnchorDate: lifecycleAnchorDate,
                snoozedUntil: snoozedUntil,
                rrule: rrule,
                calendarId: calendarId,
                googleEventId: googleEventId,
                googleEtag: googleEtag,
                remoteUpdatedAt: remoteUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String title,
                Value<String?> notes = const Value.absent(),
                Value<bool> allDay = const Value.absent(),
                Value<int?> startAt = const Value.absent(),
                Value<int?> endAt = const Value.absent(),
                Value<String?> date = const Value.absent(),
                Value<String?> timezone = const Value.absent(),
                Value<int?> doneAt = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> rolledCount = const Value.absent(),
                Value<String?> lifecycleAnchorDate = const Value.absent(),
                Value<int?> snoozedUntil = const Value.absent(),
                Value<String?> rrule = const Value.absent(),
                Value<String?> calendarId = const Value.absent(),
                Value<String?> googleEventId = const Value.absent(),
                Value<String?> googleEtag = const Value.absent(),
                Value<int?> remoteUpdatedAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion.insert(
                id: id,
                kind: kind,
                title: title,
                notes: notes,
                allDay: allDay,
                startAt: startAt,
                endAt: endAt,
                date: date,
                timezone: timezone,
                doneAt: doneAt,
                priority: priority,
                color: color,
                rolledCount: rolledCount,
                lifecycleAnchorDate: lifecycleAnchorDate,
                snoozedUntil: snoozedUntil,
                rrule: rrule,
                calendarId: calendarId,
                googleEventId: googleEventId,
                googleEtag: googleEtag,
                remoteUpdatedAt: remoteUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemsTable, Item>(table),
                  $$ItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({calendarId = false, remindersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (remindersRefs) db.reminders],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (calendarId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.calendarId,
                        referencedTable: $$ItemsTableReferences
                            ._calendarIdTable(db),
                        referencedColumn: $$ItemsTableReferences
                            ._calendarIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (remindersRefs)
                    await $_getPrefetchedDataByColumns<
                      Item,
                      $ItemsTable,
                      Reminder,
                      $RemindersTable
                    >(
                      currentTable: table,
                      referencedTable: $$ItemsTableReferences
                          ._remindersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ItemsTableReferences(db, table, p0).remindersRefs,
                      currentColumn: 'id',
                      referencedColumn: 'item_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      Item,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (Item, $$ItemsTableReferences),
      Item,
      PrefetchHooks Function({bool calendarId, bool remindersRefs})
    >;
typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  required String id,
  required String itemId,
  required int offsetMin,
  Value<String?> osNotificationId,
  Value<int> rowid,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<String> id,
  Value<String> itemId,
  Value<int> offsetMin,
  Value<String?> osNotificationId,
  Value<int> rowid,
});

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, Reminder> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('reminders__item_id__items__id');

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
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

  ColumnFilters<int> get offsetMin => $composableBuilder(
    column: $table.offsetMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get osNotificationId => $composableBuilder(
    column: $table.osNotificationId,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
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

  ColumnOrderings<int> get offsetMin => $composableBuilder(
    column: $table.offsetMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get osNotificationId => $composableBuilder(
    column: $table.osNotificationId,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get offsetMin =>
      $composableBuilder(column: $table.offsetMin, builder: (column) => column);

  GeneratedColumn<String> get osNotificationId => $composableBuilder(
    column: $table.osNotificationId,
    builder: (column) => column,
  );

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, $$RemindersTableReferences),
          Reminder,
          PrefetchHooks Function({bool itemId})
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> offsetMin = const Value.absent(),
                Value<String?> osNotificationId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                itemId: itemId,
                offsetMin: offsetMin,
                osNotificationId: osNotificationId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required int offsetMin,
                Value<String?> osNotificationId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                itemId: itemId,
                offsetMin: offsetMin,
                osNotificationId: osNotificationId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemindersTable, Reminder>(table),
                  $$RemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$RemindersTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$RemindersTableReferences
                            ._itemIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, $$RemindersTableReferences),
      Reminder,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String itemId,
  required String op,
  required String payloadJson,
  Value<int> attempts,
  Value<int?> nextTryAt,
  Value<String?> lastError,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> itemId,
  Value<String> op,
  Value<String> payloadJson,
  Value<int> attempts,
  Value<int?> nextTryAt,
  Value<String?> lastError,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextTryAt => $composableBuilder(
    column: $table.nextTryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextTryAt => $composableBuilder(
    column: $table.nextTryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get nextTryAt =>
      $composableBuilder(column: $table.nextTryAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueEntry,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueEntry,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueEntry>,
          ),
          SyncQueueEntry,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int?> nextTryAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                itemId: itemId,
                op: op,
                payloadJson: payloadJson,
                attempts: attempts,
                nextTryAt: nextTryAt,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String itemId,
                required String op,
                required String payloadJson,
                Value<int> attempts = const Value.absent(),
                Value<int?> nextTryAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                itemId: itemId,
                op: op,
                payloadJson: payloadJson,
                attempts: attempts,
                nextTryAt: nextTryAt,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueTable, SyncQueueEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncQueueTable,
                    SyncQueueEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueEntry,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueEntry,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueEntry>,
      ),
      SyncQueueEntry,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
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

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CalendarsTableTableManager get calendars =>
      $$CalendarsTableTableManager(_db, _db.calendars);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
