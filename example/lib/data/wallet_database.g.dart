// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_database.dart';

// ignore_for_file: type=lint
class $WalletRowsTable extends WalletRows
    with TableInfo<$WalletRowsTable, WalletRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalletRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secretRefMeta = const VerificationMeta(
    'secretRef',
  );
  @override
  late final GeneratedColumn<String> secretRef = GeneratedColumn<String>(
    'secret_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ready'),
  );
  static const VerificationMeta _requiresBip39PassphraseMeta =
      const VerificationMeta('requiresBip39Passphrase');
  @override
  late final GeneratedColumn<bool> requiresBip39Passphrase =
      GeneratedColumn<bool>(
        'requires_bip39_passphrase',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("requires_bip39_passphrase" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    name,
    secretRef,
    state,
    requiresBip39Passphrase,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallet_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<WalletRow> instance, {
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('secret_ref')) {
      context.handle(
        _secretRefMeta,
        secretRef.isAcceptableOrUnknown(data['secret_ref']!, _secretRefMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('requires_bip39_passphrase')) {
      context.handle(
        _requiresBip39PassphraseMeta,
        requiresBip39Passphrase.isAcceptableOrUnknown(
          data['requires_bip39_passphrase']!,
          _requiresBip39PassphraseMeta,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WalletRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WalletRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      secretRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secret_ref'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      requiresBip39Passphrase: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}requires_bip39_passphrase'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WalletRowsTable createAlias(String alias) {
    return $WalletRowsTable(attachedDatabase, alias);
  }
}

class WalletRow extends DataClass implements Insertable<WalletRow> {
  final String id;
  final String kind;
  final String name;
  final String? secretRef;
  final String state;
  final bool requiresBip39Passphrase;
  final DateTime createdAt;
  final DateTime updatedAt;
  const WalletRow({
    required this.id,
    required this.kind,
    required this.name,
    this.secretRef,
    required this.state,
    required this.requiresBip39Passphrase,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || secretRef != null) {
      map['secret_ref'] = Variable<String>(secretRef);
    }
    map['state'] = Variable<String>(state);
    map['requires_bip39_passphrase'] = Variable<bool>(requiresBip39Passphrase);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WalletRowsCompanion toCompanion(bool nullToAbsent) {
    return WalletRowsCompanion(
      id: Value(id),
      kind: Value(kind),
      name: Value(name),
      secretRef: secretRef == null && nullToAbsent
          ? const Value.absent()
          : Value(secretRef),
      state: Value(state),
      requiresBip39Passphrase: Value(requiresBip39Passphrase),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WalletRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WalletRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      secretRef: serializer.fromJson<String?>(json['secretRef']),
      state: serializer.fromJson<String>(json['state']),
      requiresBip39Passphrase: serializer.fromJson<bool>(
        json['requiresBip39Passphrase'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'secretRef': serializer.toJson<String?>(secretRef),
      'state': serializer.toJson<String>(state),
      'requiresBip39Passphrase': serializer.toJson<bool>(
        requiresBip39Passphrase,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WalletRow copyWith({
    String? id,
    String? kind,
    String? name,
    Value<String?> secretRef = const Value.absent(),
    String? state,
    bool? requiresBip39Passphrase,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WalletRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    secretRef: secretRef.present ? secretRef.value : this.secretRef,
    state: state ?? this.state,
    requiresBip39Passphrase:
        requiresBip39Passphrase ?? this.requiresBip39Passphrase,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WalletRow copyWithCompanion(WalletRowsCompanion data) {
    return WalletRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      secretRef: data.secretRef.present ? data.secretRef.value : this.secretRef,
      state: data.state.present ? data.state.value : this.state,
      requiresBip39Passphrase: data.requiresBip39Passphrase.present
          ? data.requiresBip39Passphrase.value
          : this.requiresBip39Passphrase,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WalletRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('secretRef: $secretRef, ')
          ..write('state: $state, ')
          ..write('requiresBip39Passphrase: $requiresBip39Passphrase, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    name,
    secretRef,
    state,
    requiresBip39Passphrase,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalletRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.secretRef == this.secretRef &&
          other.state == this.state &&
          other.requiresBip39Passphrase == this.requiresBip39Passphrase &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WalletRowsCompanion extends UpdateCompanion<WalletRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> name;
  final Value<String?> secretRef;
  final Value<String> state;
  final Value<bool> requiresBip39Passphrase;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WalletRowsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.secretRef = const Value.absent(),
    this.state = const Value.absent(),
    this.requiresBip39Passphrase = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WalletRowsCompanion.insert({
    required String id,
    required String kind,
    required String name,
    this.secretRef = const Value.absent(),
    this.state = const Value.absent(),
    this.requiresBip39Passphrase = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WalletRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? secretRef,
    Expression<String>? state,
    Expression<bool>? requiresBip39Passphrase,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (secretRef != null) 'secret_ref': secretRef,
      if (state != null) 'state': state,
      if (requiresBip39Passphrase != null)
        'requires_bip39_passphrase': requiresBip39Passphrase,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WalletRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? name,
    Value<String?>? secretRef,
    Value<String>? state,
    Value<bool>? requiresBip39Passphrase,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WalletRowsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      secretRef: secretRef ?? this.secretRef,
      state: state ?? this.state,
      requiresBip39Passphrase:
          requiresBip39Passphrase ?? this.requiresBip39Passphrase,
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
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (secretRef.present) {
      map['secret_ref'] = Variable<String>(secretRef.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (requiresBip39Passphrase.present) {
      map['requires_bip39_passphrase'] = Variable<bool>(
        requiresBip39Passphrase.value,
      );
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
    return (StringBuffer('WalletRowsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('secretRef: $secretRef, ')
          ..write('state: $state, ')
          ..write('requiresBip39Passphrase: $requiresBip39Passphrase, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountRowsTable extends AccountRows
    with TableInfo<$AccountRowsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _walletIdMeta = const VerificationMeta(
    'walletId',
  );
  @override
  late final GeneratedColumn<String> walletId = GeneratedColumn<String>(
    'wallet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wallet_rows (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _chainFamilyMeta = const VerificationMeta(
    'chainFamily',
  );
  @override
  late final GeneratedColumn<String> chainFamily = GeneratedColumn<String>(
    'chain_family',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coinTypeMeta = const VerificationMeta(
    'coinType',
  );
  @override
  late final GeneratedColumn<int> coinType = GeneratedColumn<int>(
    'coin_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIndexMeta = const VerificationMeta(
    'accountIndex',
  );
  @override
  late final GeneratedColumn<int> accountIndex = GeneratedColumn<int>(
    'account_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _addressFormatMeta = const VerificationMeta(
    'addressFormat',
  );
  @override
  late final GeneratedColumn<String> addressFormat = GeneratedColumn<String>(
    'address_format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _derivationProfileMeta = const VerificationMeta(
    'derivationProfile',
  );
  @override
  late final GeneratedColumn<String> derivationProfile =
      GeneratedColumn<String>(
        'derivation_profile',
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
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    walletId,
    chainFamily,
    coinType,
    accountIndex,
    addressFormat,
    derivationProfile,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('wallet_id')) {
      context.handle(
        _walletIdMeta,
        walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta),
      );
    } else if (isInserting) {
      context.missing(_walletIdMeta);
    }
    if (data.containsKey('chain_family')) {
      context.handle(
        _chainFamilyMeta,
        chainFamily.isAcceptableOrUnknown(
          data['chain_family']!,
          _chainFamilyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chainFamilyMeta);
    }
    if (data.containsKey('coin_type')) {
      context.handle(
        _coinTypeMeta,
        coinType.isAcceptableOrUnknown(data['coin_type']!, _coinTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_coinTypeMeta);
    }
    if (data.containsKey('account_index')) {
      context.handle(
        _accountIndexMeta,
        accountIndex.isAcceptableOrUnknown(
          data['account_index']!,
          _accountIndexMeta,
        ),
      );
    }
    if (data.containsKey('address_format')) {
      context.handle(
        _addressFormatMeta,
        addressFormat.isAcceptableOrUnknown(
          data['address_format']!,
          _addressFormatMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_addressFormatMeta);
    }
    if (data.containsKey('derivation_profile')) {
      context.handle(
        _derivationProfileMeta,
        derivationProfile.isAcceptableOrUnknown(
          data['derivation_profile']!,
          _derivationProfileMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_derivationProfileMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      walletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallet_id'],
      )!,
      chainFamily: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chain_family'],
      )!,
      coinType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}coin_type'],
      )!,
      accountIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_index'],
      )!,
      addressFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address_format'],
      )!,
      derivationProfile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}derivation_profile'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AccountRowsTable createAlias(String alias) {
    return $AccountRowsTable(attachedDatabase, alias);
  }
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final String id;
  final String walletId;
  final String chainFamily;
  final int coinType;
  final int accountIndex;
  final String addressFormat;
  final String derivationProfile;
  final DateTime createdAt;
  const AccountRow({
    required this.id,
    required this.walletId,
    required this.chainFamily,
    required this.coinType,
    required this.accountIndex,
    required this.addressFormat,
    required this.derivationProfile,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['wallet_id'] = Variable<String>(walletId);
    map['chain_family'] = Variable<String>(chainFamily);
    map['coin_type'] = Variable<int>(coinType);
    map['account_index'] = Variable<int>(accountIndex);
    map['address_format'] = Variable<String>(addressFormat);
    map['derivation_profile'] = Variable<String>(derivationProfile);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountRowsCompanion toCompanion(bool nullToAbsent) {
    return AccountRowsCompanion(
      id: Value(id),
      walletId: Value(walletId),
      chainFamily: Value(chainFamily),
      coinType: Value(coinType),
      accountIndex: Value(accountIndex),
      addressFormat: Value(addressFormat),
      derivationProfile: Value(derivationProfile),
      createdAt: Value(createdAt),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<String>(json['id']),
      walletId: serializer.fromJson<String>(json['walletId']),
      chainFamily: serializer.fromJson<String>(json['chainFamily']),
      coinType: serializer.fromJson<int>(json['coinType']),
      accountIndex: serializer.fromJson<int>(json['accountIndex']),
      addressFormat: serializer.fromJson<String>(json['addressFormat']),
      derivationProfile: serializer.fromJson<String>(json['derivationProfile']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'walletId': serializer.toJson<String>(walletId),
      'chainFamily': serializer.toJson<String>(chainFamily),
      'coinType': serializer.toJson<int>(coinType),
      'accountIndex': serializer.toJson<int>(accountIndex),
      'addressFormat': serializer.toJson<String>(addressFormat),
      'derivationProfile': serializer.toJson<String>(derivationProfile),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AccountRow copyWith({
    String? id,
    String? walletId,
    String? chainFamily,
    int? coinType,
    int? accountIndex,
    String? addressFormat,
    String? derivationProfile,
    DateTime? createdAt,
  }) => AccountRow(
    id: id ?? this.id,
    walletId: walletId ?? this.walletId,
    chainFamily: chainFamily ?? this.chainFamily,
    coinType: coinType ?? this.coinType,
    accountIndex: accountIndex ?? this.accountIndex,
    addressFormat: addressFormat ?? this.addressFormat,
    derivationProfile: derivationProfile ?? this.derivationProfile,
    createdAt: createdAt ?? this.createdAt,
  );
  AccountRow copyWithCompanion(AccountRowsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      chainFamily: data.chainFamily.present
          ? data.chainFamily.value
          : this.chainFamily,
      coinType: data.coinType.present ? data.coinType.value : this.coinType,
      accountIndex: data.accountIndex.present
          ? data.accountIndex.value
          : this.accountIndex,
      addressFormat: data.addressFormat.present
          ? data.addressFormat.value
          : this.addressFormat,
      derivationProfile: data.derivationProfile.present
          ? data.derivationProfile.value
          : this.derivationProfile,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('walletId: $walletId, ')
          ..write('chainFamily: $chainFamily, ')
          ..write('coinType: $coinType, ')
          ..write('accountIndex: $accountIndex, ')
          ..write('addressFormat: $addressFormat, ')
          ..write('derivationProfile: $derivationProfile, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    walletId,
    chainFamily,
    coinType,
    accountIndex,
    addressFormat,
    derivationProfile,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.walletId == this.walletId &&
          other.chainFamily == this.chainFamily &&
          other.coinType == this.coinType &&
          other.accountIndex == this.accountIndex &&
          other.addressFormat == this.addressFormat &&
          other.derivationProfile == this.derivationProfile &&
          other.createdAt == this.createdAt);
}

class AccountRowsCompanion extends UpdateCompanion<AccountRow> {
  final Value<String> id;
  final Value<String> walletId;
  final Value<String> chainFamily;
  final Value<int> coinType;
  final Value<int> accountIndex;
  final Value<String> addressFormat;
  final Value<String> derivationProfile;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AccountRowsCompanion({
    this.id = const Value.absent(),
    this.walletId = const Value.absent(),
    this.chainFamily = const Value.absent(),
    this.coinType = const Value.absent(),
    this.accountIndex = const Value.absent(),
    this.addressFormat = const Value.absent(),
    this.derivationProfile = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountRowsCompanion.insert({
    required String id,
    required String walletId,
    required String chainFamily,
    required int coinType,
    this.accountIndex = const Value.absent(),
    required String addressFormat,
    required String derivationProfile,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       walletId = Value(walletId),
       chainFamily = Value(chainFamily),
       coinType = Value(coinType),
       addressFormat = Value(addressFormat),
       derivationProfile = Value(derivationProfile),
       createdAt = Value(createdAt);
  static Insertable<AccountRow> custom({
    Expression<String>? id,
    Expression<String>? walletId,
    Expression<String>? chainFamily,
    Expression<int>? coinType,
    Expression<int>? accountIndex,
    Expression<String>? addressFormat,
    Expression<String>? derivationProfile,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (walletId != null) 'wallet_id': walletId,
      if (chainFamily != null) 'chain_family': chainFamily,
      if (coinType != null) 'coin_type': coinType,
      if (accountIndex != null) 'account_index': accountIndex,
      if (addressFormat != null) 'address_format': addressFormat,
      if (derivationProfile != null) 'derivation_profile': derivationProfile,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? walletId,
    Value<String>? chainFamily,
    Value<int>? coinType,
    Value<int>? accountIndex,
    Value<String>? addressFormat,
    Value<String>? derivationProfile,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AccountRowsCompanion(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      chainFamily: chainFamily ?? this.chainFamily,
      coinType: coinType ?? this.coinType,
      accountIndex: accountIndex ?? this.accountIndex,
      addressFormat: addressFormat ?? this.addressFormat,
      derivationProfile: derivationProfile ?? this.derivationProfile,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<String>(walletId.value);
    }
    if (chainFamily.present) {
      map['chain_family'] = Variable<String>(chainFamily.value);
    }
    if (coinType.present) {
      map['coin_type'] = Variable<int>(coinType.value);
    }
    if (accountIndex.present) {
      map['account_index'] = Variable<int>(accountIndex.value);
    }
    if (addressFormat.present) {
      map['address_format'] = Variable<String>(addressFormat.value);
    }
    if (derivationProfile.present) {
      map['derivation_profile'] = Variable<String>(derivationProfile.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountRowsCompanion(')
          ..write('id: $id, ')
          ..write('walletId: $walletId, ')
          ..write('chainFamily: $chainFamily, ')
          ..write('coinType: $coinType, ')
          ..write('accountIndex: $accountIndex, ')
          ..write('addressFormat: $addressFormat, ')
          ..write('derivationProfile: $derivationProfile, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AddressRowsTable extends AddressRows
    with TableInfo<$AddressRowsTable, AddressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AddressRowsTable(this.attachedDatabase, [this._alias]);
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
      'REFERENCES account_rows (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _derivationPathMeta = const VerificationMeta(
    'derivationPath',
  );
  @override
  late final GeneratedColumn<String> derivationPath = GeneratedColumn<String>(
    'derivation_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _changeIndexMeta = const VerificationMeta(
    'changeIndex',
  );
  @override
  late final GeneratedColumn<int> changeIndex = GeneratedColumn<int>(
    'change_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressIndexMeta = const VerificationMeta(
    'addressIndex',
  );
  @override
  late final GeneratedColumn<int> addressIndex = GeneratedColumn<int>(
    'address_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressNormalizedMeta = const VerificationMeta(
    'addressNormalized',
  );
  @override
  late final GeneratedColumn<String> addressNormalized =
      GeneratedColumn<String>(
        'address_normalized',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    derivationPath,
    changeIndex,
    addressIndex,
    address,
    addressNormalized,
    isPrimary,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'address_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AddressRow> instance, {
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
    if (data.containsKey('derivation_path')) {
      context.handle(
        _derivationPathMeta,
        derivationPath.isAcceptableOrUnknown(
          data['derivation_path']!,
          _derivationPathMeta,
        ),
      );
    }
    if (data.containsKey('change_index')) {
      context.handle(
        _changeIndexMeta,
        changeIndex.isAcceptableOrUnknown(
          data['change_index']!,
          _changeIndexMeta,
        ),
      );
    }
    if (data.containsKey('address_index')) {
      context.handle(
        _addressIndexMeta,
        addressIndex.isAcceptableOrUnknown(
          data['address_index']!,
          _addressIndexMeta,
        ),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('address_normalized')) {
      context.handle(
        _addressNormalizedMeta,
        addressNormalized.isAcceptableOrUnknown(
          data['address_normalized']!,
          _addressNormalizedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_addressNormalizedMeta);
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AddressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AddressRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      derivationPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}derivation_path'],
      )!,
      changeIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_index'],
      ),
      addressIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}address_index'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      addressNormalized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address_normalized'],
      )!,
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
    );
  }

  @override
  $AddressRowsTable createAlias(String alias) {
    return $AddressRowsTable(attachedDatabase, alias);
  }
}

class AddressRow extends DataClass implements Insertable<AddressRow> {
  final String id;
  final String accountId;
  final String derivationPath;
  final int? changeIndex;
  final int? addressIndex;
  final String address;
  final String addressNormalized;
  final bool isPrimary;
  const AddressRow({
    required this.id,
    required this.accountId,
    required this.derivationPath,
    this.changeIndex,
    this.addressIndex,
    required this.address,
    required this.addressNormalized,
    required this.isPrimary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['derivation_path'] = Variable<String>(derivationPath);
    if (!nullToAbsent || changeIndex != null) {
      map['change_index'] = Variable<int>(changeIndex);
    }
    if (!nullToAbsent || addressIndex != null) {
      map['address_index'] = Variable<int>(addressIndex);
    }
    map['address'] = Variable<String>(address);
    map['address_normalized'] = Variable<String>(addressNormalized);
    map['is_primary'] = Variable<bool>(isPrimary);
    return map;
  }

  AddressRowsCompanion toCompanion(bool nullToAbsent) {
    return AddressRowsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      derivationPath: Value(derivationPath),
      changeIndex: changeIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(changeIndex),
      addressIndex: addressIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(addressIndex),
      address: Value(address),
      addressNormalized: Value(addressNormalized),
      isPrimary: Value(isPrimary),
    );
  }

  factory AddressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AddressRow(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      derivationPath: serializer.fromJson<String>(json['derivationPath']),
      changeIndex: serializer.fromJson<int?>(json['changeIndex']),
      addressIndex: serializer.fromJson<int?>(json['addressIndex']),
      address: serializer.fromJson<String>(json['address']),
      addressNormalized: serializer.fromJson<String>(json['addressNormalized']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'derivationPath': serializer.toJson<String>(derivationPath),
      'changeIndex': serializer.toJson<int?>(changeIndex),
      'addressIndex': serializer.toJson<int?>(addressIndex),
      'address': serializer.toJson<String>(address),
      'addressNormalized': serializer.toJson<String>(addressNormalized),
      'isPrimary': serializer.toJson<bool>(isPrimary),
    };
  }

  AddressRow copyWith({
    String? id,
    String? accountId,
    String? derivationPath,
    Value<int?> changeIndex = const Value.absent(),
    Value<int?> addressIndex = const Value.absent(),
    String? address,
    String? addressNormalized,
    bool? isPrimary,
  }) => AddressRow(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    derivationPath: derivationPath ?? this.derivationPath,
    changeIndex: changeIndex.present ? changeIndex.value : this.changeIndex,
    addressIndex: addressIndex.present ? addressIndex.value : this.addressIndex,
    address: address ?? this.address,
    addressNormalized: addressNormalized ?? this.addressNormalized,
    isPrimary: isPrimary ?? this.isPrimary,
  );
  AddressRow copyWithCompanion(AddressRowsCompanion data) {
    return AddressRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      derivationPath: data.derivationPath.present
          ? data.derivationPath.value
          : this.derivationPath,
      changeIndex: data.changeIndex.present
          ? data.changeIndex.value
          : this.changeIndex,
      addressIndex: data.addressIndex.present
          ? data.addressIndex.value
          : this.addressIndex,
      address: data.address.present ? data.address.value : this.address,
      addressNormalized: data.addressNormalized.present
          ? data.addressNormalized.value
          : this.addressNormalized,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AddressRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('derivationPath: $derivationPath, ')
          ..write('changeIndex: $changeIndex, ')
          ..write('addressIndex: $addressIndex, ')
          ..write('address: $address, ')
          ..write('addressNormalized: $addressNormalized, ')
          ..write('isPrimary: $isPrimary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    derivationPath,
    changeIndex,
    addressIndex,
    address,
    addressNormalized,
    isPrimary,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AddressRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.derivationPath == this.derivationPath &&
          other.changeIndex == this.changeIndex &&
          other.addressIndex == this.addressIndex &&
          other.address == this.address &&
          other.addressNormalized == this.addressNormalized &&
          other.isPrimary == this.isPrimary);
}

class AddressRowsCompanion extends UpdateCompanion<AddressRow> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> derivationPath;
  final Value<int?> changeIndex;
  final Value<int?> addressIndex;
  final Value<String> address;
  final Value<String> addressNormalized;
  final Value<bool> isPrimary;
  final Value<int> rowid;
  const AddressRowsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.derivationPath = const Value.absent(),
    this.changeIndex = const Value.absent(),
    this.addressIndex = const Value.absent(),
    this.address = const Value.absent(),
    this.addressNormalized = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AddressRowsCompanion.insert({
    required String id,
    required String accountId,
    this.derivationPath = const Value.absent(),
    this.changeIndex = const Value.absent(),
    this.addressIndex = const Value.absent(),
    required String address,
    required String addressNormalized,
    this.isPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       address = Value(address),
       addressNormalized = Value(addressNormalized);
  static Insertable<AddressRow> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? derivationPath,
    Expression<int>? changeIndex,
    Expression<int>? addressIndex,
    Expression<String>? address,
    Expression<String>? addressNormalized,
    Expression<bool>? isPrimary,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (derivationPath != null) 'derivation_path': derivationPath,
      if (changeIndex != null) 'change_index': changeIndex,
      if (addressIndex != null) 'address_index': addressIndex,
      if (address != null) 'address': address,
      if (addressNormalized != null) 'address_normalized': addressNormalized,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AddressRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? derivationPath,
    Value<int?>? changeIndex,
    Value<int?>? addressIndex,
    Value<String>? address,
    Value<String>? addressNormalized,
    Value<bool>? isPrimary,
    Value<int>? rowid,
  }) {
    return AddressRowsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      derivationPath: derivationPath ?? this.derivationPath,
      changeIndex: changeIndex ?? this.changeIndex,
      addressIndex: addressIndex ?? this.addressIndex,
      address: address ?? this.address,
      addressNormalized: addressNormalized ?? this.addressNormalized,
      isPrimary: isPrimary ?? this.isPrimary,
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
    if (derivationPath.present) {
      map['derivation_path'] = Variable<String>(derivationPath.value);
    }
    if (changeIndex.present) {
      map['change_index'] = Variable<int>(changeIndex.value);
    }
    if (addressIndex.present) {
      map['address_index'] = Variable<int>(addressIndex.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (addressNormalized.present) {
      map['address_normalized'] = Variable<String>(addressNormalized.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AddressRowsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('derivationPath: $derivationPath, ')
          ..write('changeIndex: $changeIndex, ')
          ..write('addressIndex: $addressIndex, ')
          ..write('address: $address, ')
          ..write('addressNormalized: $addressNormalized, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NetworkRowsTable extends NetworkRows
    with TableInfo<$NetworkRowsTable, NetworkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NetworkRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chainFamilyMeta = const VerificationMeta(
    'chainFamily',
  );
  @override
  late final GeneratedColumn<String> chainFamily = GeneratedColumn<String>(
    'chain_family',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, chainFamily, displayName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'network_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<NetworkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('chain_family')) {
      context.handle(
        _chainFamilyMeta,
        chainFamily.isAcceptableOrUnknown(
          data['chain_family']!,
          _chainFamilyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chainFamilyMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NetworkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NetworkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      chainFamily: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chain_family'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
    );
  }

  @override
  $NetworkRowsTable createAlias(String alias) {
    return $NetworkRowsTable(attachedDatabase, alias);
  }
}

class NetworkRow extends DataClass implements Insertable<NetworkRow> {
  final String id;
  final String chainFamily;
  final String displayName;
  const NetworkRow({
    required this.id,
    required this.chainFamily,
    required this.displayName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['chain_family'] = Variable<String>(chainFamily);
    map['display_name'] = Variable<String>(displayName);
    return map;
  }

  NetworkRowsCompanion toCompanion(bool nullToAbsent) {
    return NetworkRowsCompanion(
      id: Value(id),
      chainFamily: Value(chainFamily),
      displayName: Value(displayName),
    );
  }

  factory NetworkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NetworkRow(
      id: serializer.fromJson<String>(json['id']),
      chainFamily: serializer.fromJson<String>(json['chainFamily']),
      displayName: serializer.fromJson<String>(json['displayName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'chainFamily': serializer.toJson<String>(chainFamily),
      'displayName': serializer.toJson<String>(displayName),
    };
  }

  NetworkRow copyWith({String? id, String? chainFamily, String? displayName}) =>
      NetworkRow(
        id: id ?? this.id,
        chainFamily: chainFamily ?? this.chainFamily,
        displayName: displayName ?? this.displayName,
      );
  NetworkRow copyWithCompanion(NetworkRowsCompanion data) {
    return NetworkRow(
      id: data.id.present ? data.id.value : this.id,
      chainFamily: data.chainFamily.present
          ? data.chainFamily.value
          : this.chainFamily,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NetworkRow(')
          ..write('id: $id, ')
          ..write('chainFamily: $chainFamily, ')
          ..write('displayName: $displayName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, chainFamily, displayName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NetworkRow &&
          other.id == this.id &&
          other.chainFamily == this.chainFamily &&
          other.displayName == this.displayName);
}

class NetworkRowsCompanion extends UpdateCompanion<NetworkRow> {
  final Value<String> id;
  final Value<String> chainFamily;
  final Value<String> displayName;
  final Value<int> rowid;
  const NetworkRowsCompanion({
    this.id = const Value.absent(),
    this.chainFamily = const Value.absent(),
    this.displayName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NetworkRowsCompanion.insert({
    required String id,
    required String chainFamily,
    required String displayName,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       chainFamily = Value(chainFamily),
       displayName = Value(displayName);
  static Insertable<NetworkRow> custom({
    Expression<String>? id,
    Expression<String>? chainFamily,
    Expression<String>? displayName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chainFamily != null) 'chain_family': chainFamily,
      if (displayName != null) 'display_name': displayName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NetworkRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? chainFamily,
    Value<String>? displayName,
    Value<int>? rowid,
  }) {
    return NetworkRowsCompanion(
      id: id ?? this.id,
      chainFamily: chainFamily ?? this.chainFamily,
      displayName: displayName ?? this.displayName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (chainFamily.present) {
      map['chain_family'] = Variable<String>(chainFamily.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NetworkRowsCompanion(')
          ..write('id: $id, ')
          ..write('chainFamily: $chainFamily, ')
          ..write('displayName: $displayName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountNetworkRowsTable extends AccountNetworkRows
    with TableInfo<$AccountNetworkRowsTable, AccountNetworkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountNetworkRowsTable(this.attachedDatabase, [this._alias]);
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
      'REFERENCES account_rows (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _networkIdMeta = const VerificationMeta(
    'networkId',
  );
  @override
  late final GeneratedColumn<String> networkId = GeneratedColumn<String>(
    'network_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES network_rows (id)',
    ),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [accountId, networkId, enabled];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_network_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountNetworkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('network_id')) {
      context.handle(
        _networkIdMeta,
        networkId.isAcceptableOrUnknown(data['network_id']!, _networkIdMeta),
      );
    } else if (isInserting) {
      context.missing(_networkIdMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, networkId};
  @override
  AccountNetworkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountNetworkRow(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      networkId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}network_id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $AccountNetworkRowsTable createAlias(String alias) {
    return $AccountNetworkRowsTable(attachedDatabase, alias);
  }
}

class AccountNetworkRow extends DataClass
    implements Insertable<AccountNetworkRow> {
  final String accountId;
  final String networkId;
  final bool enabled;
  const AccountNetworkRow({
    required this.accountId,
    required this.networkId,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['network_id'] = Variable<String>(networkId);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  AccountNetworkRowsCompanion toCompanion(bool nullToAbsent) {
    return AccountNetworkRowsCompanion(
      accountId: Value(accountId),
      networkId: Value(networkId),
      enabled: Value(enabled),
    );
  }

  factory AccountNetworkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountNetworkRow(
      accountId: serializer.fromJson<String>(json['accountId']),
      networkId: serializer.fromJson<String>(json['networkId']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'networkId': serializer.toJson<String>(networkId),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  AccountNetworkRow copyWith({
    String? accountId,
    String? networkId,
    bool? enabled,
  }) => AccountNetworkRow(
    accountId: accountId ?? this.accountId,
    networkId: networkId ?? this.networkId,
    enabled: enabled ?? this.enabled,
  );
  AccountNetworkRow copyWithCompanion(AccountNetworkRowsCompanion data) {
    return AccountNetworkRow(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      networkId: data.networkId.present ? data.networkId.value : this.networkId,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountNetworkRow(')
          ..write('accountId: $accountId, ')
          ..write('networkId: $networkId, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, networkId, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountNetworkRow &&
          other.accountId == this.accountId &&
          other.networkId == this.networkId &&
          other.enabled == this.enabled);
}

class AccountNetworkRowsCompanion extends UpdateCompanion<AccountNetworkRow> {
  final Value<String> accountId;
  final Value<String> networkId;
  final Value<bool> enabled;
  final Value<int> rowid;
  const AccountNetworkRowsCompanion({
    this.accountId = const Value.absent(),
    this.networkId = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountNetworkRowsCompanion.insert({
    required String accountId,
    required String networkId,
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       networkId = Value(networkId);
  static Insertable<AccountNetworkRow> custom({
    Expression<String>? accountId,
    Expression<String>? networkId,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (networkId != null) 'network_id': networkId,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountNetworkRowsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? networkId,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return AccountNetworkRowsCompanion(
      accountId: accountId ?? this.accountId,
      networkId: networkId ?? this.networkId,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (networkId.present) {
      map['network_id'] = Variable<String>(networkId.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountNetworkRowsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('networkId: $networkId, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BackupStatusRowsTable extends BackupStatusRows
    with TableInfo<$BackupStatusRowsTable, BackupStatusRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupStatusRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _walletIdMeta = const VerificationMeta(
    'walletId',
  );
  @override
  late final GeneratedColumn<String> walletId = GeneratedColumn<String>(
    'wallet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wallet_rows (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _remoteChecksumMeta = const VerificationMeta(
    'remoteChecksum',
  );
  @override
  late final GeneratedColumn<String> remoteChecksum = GeneratedColumn<String>(
    'remote_checksum',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastVerifiedAtMeta = const VerificationMeta(
    'lastVerifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastVerifiedAt =
      GeneratedColumn<DateTime>(
        'last_verified_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    walletId,
    state,
    remoteChecksum,
    lastVerifiedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_status_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<BackupStatusRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('wallet_id')) {
      context.handle(
        _walletIdMeta,
        walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta),
      );
    } else if (isInserting) {
      context.missing(_walletIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('remote_checksum')) {
      context.handle(
        _remoteChecksumMeta,
        remoteChecksum.isAcceptableOrUnknown(
          data['remote_checksum']!,
          _remoteChecksumMeta,
        ),
      );
    }
    if (data.containsKey('last_verified_at')) {
      context.handle(
        _lastVerifiedAtMeta,
        lastVerifiedAt.isAcceptableOrUnknown(
          data['last_verified_at']!,
          _lastVerifiedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {walletId};
  @override
  BackupStatusRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupStatusRow(
      walletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallet_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      remoteChecksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_checksum'],
      ),
      lastVerifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_verified_at'],
      ),
    );
  }

  @override
  $BackupStatusRowsTable createAlias(String alias) {
    return $BackupStatusRowsTable(attachedDatabase, alias);
  }
}

class BackupStatusRow extends DataClass implements Insertable<BackupStatusRow> {
  final String walletId;
  final String state;
  final String? remoteChecksum;
  final DateTime? lastVerifiedAt;
  const BackupStatusRow({
    required this.walletId,
    required this.state,
    this.remoteChecksum,
    this.lastVerifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['wallet_id'] = Variable<String>(walletId);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || remoteChecksum != null) {
      map['remote_checksum'] = Variable<String>(remoteChecksum);
    }
    if (!nullToAbsent || lastVerifiedAt != null) {
      map['last_verified_at'] = Variable<DateTime>(lastVerifiedAt);
    }
    return map;
  }

  BackupStatusRowsCompanion toCompanion(bool nullToAbsent) {
    return BackupStatusRowsCompanion(
      walletId: Value(walletId),
      state: Value(state),
      remoteChecksum: remoteChecksum == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteChecksum),
      lastVerifiedAt: lastVerifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVerifiedAt),
    );
  }

  factory BackupStatusRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupStatusRow(
      walletId: serializer.fromJson<String>(json['walletId']),
      state: serializer.fromJson<String>(json['state']),
      remoteChecksum: serializer.fromJson<String?>(json['remoteChecksum']),
      lastVerifiedAt: serializer.fromJson<DateTime?>(json['lastVerifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'walletId': serializer.toJson<String>(walletId),
      'state': serializer.toJson<String>(state),
      'remoteChecksum': serializer.toJson<String?>(remoteChecksum),
      'lastVerifiedAt': serializer.toJson<DateTime?>(lastVerifiedAt),
    };
  }

  BackupStatusRow copyWith({
    String? walletId,
    String? state,
    Value<String?> remoteChecksum = const Value.absent(),
    Value<DateTime?> lastVerifiedAt = const Value.absent(),
  }) => BackupStatusRow(
    walletId: walletId ?? this.walletId,
    state: state ?? this.state,
    remoteChecksum: remoteChecksum.present
        ? remoteChecksum.value
        : this.remoteChecksum,
    lastVerifiedAt: lastVerifiedAt.present
        ? lastVerifiedAt.value
        : this.lastVerifiedAt,
  );
  BackupStatusRow copyWithCompanion(BackupStatusRowsCompanion data) {
    return BackupStatusRow(
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      state: data.state.present ? data.state.value : this.state,
      remoteChecksum: data.remoteChecksum.present
          ? data.remoteChecksum.value
          : this.remoteChecksum,
      lastVerifiedAt: data.lastVerifiedAt.present
          ? data.lastVerifiedAt.value
          : this.lastVerifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupStatusRow(')
          ..write('walletId: $walletId, ')
          ..write('state: $state, ')
          ..write('remoteChecksum: $remoteChecksum, ')
          ..write('lastVerifiedAt: $lastVerifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(walletId, state, remoteChecksum, lastVerifiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupStatusRow &&
          other.walletId == this.walletId &&
          other.state == this.state &&
          other.remoteChecksum == this.remoteChecksum &&
          other.lastVerifiedAt == this.lastVerifiedAt);
}

class BackupStatusRowsCompanion extends UpdateCompanion<BackupStatusRow> {
  final Value<String> walletId;
  final Value<String> state;
  final Value<String?> remoteChecksum;
  final Value<DateTime?> lastVerifiedAt;
  final Value<int> rowid;
  const BackupStatusRowsCompanion({
    this.walletId = const Value.absent(),
    this.state = const Value.absent(),
    this.remoteChecksum = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BackupStatusRowsCompanion.insert({
    required String walletId,
    this.state = const Value.absent(),
    this.remoteChecksum = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : walletId = Value(walletId);
  static Insertable<BackupStatusRow> custom({
    Expression<String>? walletId,
    Expression<String>? state,
    Expression<String>? remoteChecksum,
    Expression<DateTime>? lastVerifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (walletId != null) 'wallet_id': walletId,
      if (state != null) 'state': state,
      if (remoteChecksum != null) 'remote_checksum': remoteChecksum,
      if (lastVerifiedAt != null) 'last_verified_at': lastVerifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BackupStatusRowsCompanion copyWith({
    Value<String>? walletId,
    Value<String>? state,
    Value<String?>? remoteChecksum,
    Value<DateTime?>? lastVerifiedAt,
    Value<int>? rowid,
  }) {
    return BackupStatusRowsCompanion(
      walletId: walletId ?? this.walletId,
      state: state ?? this.state,
      remoteChecksum: remoteChecksum ?? this.remoteChecksum,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (walletId.present) {
      map['wallet_id'] = Variable<String>(walletId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (remoteChecksum.present) {
      map['remote_checksum'] = Variable<String>(remoteChecksum.value);
    }
    if (lastVerifiedAt.present) {
      map['last_verified_at'] = Variable<DateTime>(lastVerifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupStatusRowsCompanion(')
          ..write('walletId: $walletId, ')
          ..write('state: $state, ')
          ..write('remoteChecksum: $remoteChecksum, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$WalletDatabase extends GeneratedDatabase {
  _$WalletDatabase(QueryExecutor e) : super(e);
  $WalletDatabaseManager get managers => $WalletDatabaseManager(this);
  late final $WalletRowsTable walletRows = $WalletRowsTable(this);
  late final $AccountRowsTable accountRows = $AccountRowsTable(this);
  late final $AddressRowsTable addressRows = $AddressRowsTable(this);
  late final $NetworkRowsTable networkRows = $NetworkRowsTable(this);
  late final $AccountNetworkRowsTable accountNetworkRows =
      $AccountNetworkRowsTable(this);
  late final $BackupStatusRowsTable backupStatusRows = $BackupStatusRowsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    walletRows,
    accountRows,
    addressRows,
    networkRows,
    accountNetworkRows,
    backupStatusRows,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'wallet_rows',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('account_rows', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'account_rows',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('address_rows', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'account_rows',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('account_network_rows', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'wallet_rows',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('backup_status_rows', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$WalletRowsTableCreateCompanionBuilder =
    WalletRowsCompanion Function({
      required String id,
      required String kind,
      required String name,
      Value<String?> secretRef,
      Value<String> state,
      Value<bool> requiresBip39Passphrase,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$WalletRowsTableUpdateCompanionBuilder =
    WalletRowsCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> name,
      Value<String?> secretRef,
      Value<String> state,
      Value<bool> requiresBip39Passphrase,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$WalletRowsTableReferences
    extends BaseReferences<_$WalletDatabase, $WalletRowsTable, WalletRow> {
  $$WalletRowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AccountRowsTable, List<AccountRow>>
  _accountRowsRefsTable(_$WalletDatabase db) => MultiTypedResultKey.fromTable(
    db.accountRows,
    aliasName: 'wallet_rows__id__account_rows__wallet_id',
  );

  $$AccountRowsTableProcessedTableManager get accountRowsRefs {
    final manager = $$AccountRowsTableTableManager(
      $_db,
      $_db.accountRows,
    ).filter((f) => f.walletId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_accountRowsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BackupStatusRowsTable, List<BackupStatusRow>>
  _backupStatusRowsRefsTable(_$WalletDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.backupStatusRows,
        aliasName: 'wallet_rows__id__backup_status_rows__wallet_id',
      );

  $$BackupStatusRowsTableProcessedTableManager get backupStatusRowsRefs {
    final manager = $$BackupStatusRowsTableTableManager(
      $_db,
      $_db.backupStatusRows,
    ).filter((f) => f.walletId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _backupStatusRowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WalletRowsTableFilterComposer
    extends Composer<_$WalletDatabase, $WalletRowsTable> {
  $$WalletRowsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secretRef => $composableBuilder(
    column: $table.secretRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get requiresBip39Passphrase => $composableBuilder(
    column: $table.requiresBip39Passphrase,
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

  Expression<bool> accountRowsRefs(
    Expression<bool> Function($$AccountRowsTableFilterComposer f) f,
  ) {
    final $$AccountRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountRows,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountRowsTableFilterComposer(
            $db: $db,
            $table: $db.accountRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> backupStatusRowsRefs(
    Expression<bool> Function($$BackupStatusRowsTableFilterComposer f) f,
  ) {
    final $$BackupStatusRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.backupStatusRows,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupStatusRowsTableFilterComposer(
            $db: $db,
            $table: $db.backupStatusRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WalletRowsTableOrderingComposer
    extends Composer<_$WalletDatabase, $WalletRowsTable> {
  $$WalletRowsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secretRef => $composableBuilder(
    column: $table.secretRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get requiresBip39Passphrase => $composableBuilder(
    column: $table.requiresBip39Passphrase,
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

class $$WalletRowsTableAnnotationComposer
    extends Composer<_$WalletDatabase, $WalletRowsTable> {
  $$WalletRowsTableAnnotationComposer({
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get secretRef =>
      $composableBuilder(column: $table.secretRef, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<bool> get requiresBip39Passphrase => $composableBuilder(
    column: $table.requiresBip39Passphrase,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> accountRowsRefs<T extends Object>(
    Expression<T> Function($$AccountRowsTableAnnotationComposer a) f,
  ) {
    final $$AccountRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountRows,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.accountRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> backupStatusRowsRefs<T extends Object>(
    Expression<T> Function($$BackupStatusRowsTableAnnotationComposer a) f,
  ) {
    final $$BackupStatusRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.backupStatusRows,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupStatusRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.backupStatusRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WalletRowsTableTableManager
    extends
        RootTableManager<
          _$WalletDatabase,
          $WalletRowsTable,
          WalletRow,
          $$WalletRowsTableFilterComposer,
          $$WalletRowsTableOrderingComposer,
          $$WalletRowsTableAnnotationComposer,
          $$WalletRowsTableCreateCompanionBuilder,
          $$WalletRowsTableUpdateCompanionBuilder,
          (WalletRow, $$WalletRowsTableReferences),
          WalletRow,
          PrefetchHooks Function({
            bool accountRowsRefs,
            bool backupStatusRowsRefs,
          })
        > {
  $$WalletRowsTableTableManager(_$WalletDatabase db, $WalletRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalletRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalletRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalletRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> secretRef = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<bool> requiresBip39Passphrase = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WalletRowsCompanion(
                id: id,
                kind: kind,
                name: name,
                secretRef: secretRef,
                state: state,
                requiresBip39Passphrase: requiresBip39Passphrase,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String name,
                Value<String?> secretRef = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<bool> requiresBip39Passphrase = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WalletRowsCompanion.insert(
                id: id,
                kind: kind,
                name: name,
                secretRef: secretRef,
                state: state,
                requiresBip39Passphrase: requiresBip39Passphrase,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WalletRowsTable, WalletRow>(table),
                  $$WalletRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({accountRowsRefs = false, backupStatusRowsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (accountRowsRefs) db.accountRows,
                    if (backupStatusRowsRefs) db.backupStatusRows,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (accountRowsRefs)
                        await $_getPrefetchedData<
                          WalletRow,
                          $WalletRowsTable,
                          AccountRow
                        >(
                          currentTable: table,
                          referencedTable: $$WalletRowsTableReferences
                              ._accountRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WalletRowsTableReferences(
                                db,
                                table,
                                p0,
                              ).accountRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.walletId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (backupStatusRowsRefs)
                        await $_getPrefetchedData<
                          WalletRow,
                          $WalletRowsTable,
                          BackupStatusRow
                        >(
                          currentTable: table,
                          referencedTable: $$WalletRowsTableReferences
                              ._backupStatusRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WalletRowsTableReferences(
                                db,
                                table,
                                p0,
                              ).backupStatusRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.walletId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WalletRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$WalletDatabase,
      $WalletRowsTable,
      WalletRow,
      $$WalletRowsTableFilterComposer,
      $$WalletRowsTableOrderingComposer,
      $$WalletRowsTableAnnotationComposer,
      $$WalletRowsTableCreateCompanionBuilder,
      $$WalletRowsTableUpdateCompanionBuilder,
      (WalletRow, $$WalletRowsTableReferences),
      WalletRow,
      PrefetchHooks Function({bool accountRowsRefs, bool backupStatusRowsRefs})
    >;
typedef $$AccountRowsTableCreateCompanionBuilder =
    AccountRowsCompanion Function({
      required String id,
      required String walletId,
      required String chainFamily,
      required int coinType,
      Value<int> accountIndex,
      required String addressFormat,
      required String derivationProfile,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AccountRowsTableUpdateCompanionBuilder =
    AccountRowsCompanion Function({
      Value<String> id,
      Value<String> walletId,
      Value<String> chainFamily,
      Value<int> coinType,
      Value<int> accountIndex,
      Value<String> addressFormat,
      Value<String> derivationProfile,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AccountRowsTableReferences
    extends BaseReferences<_$WalletDatabase, $AccountRowsTable, AccountRow> {
  $$AccountRowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WalletRowsTable _walletIdTable(_$WalletDatabase db) =>
      db.walletRows.createAlias('account_rows__wallet_id__wallet_rows__id');

  $$WalletRowsTableProcessedTableManager get walletId {
    final $_column = $_itemColumn<String>('wallet_id')!;

    final manager = $$WalletRowsTableTableManager(
      $_db,
      $_db.walletRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AddressRowsTable, List<AddressRow>>
  _addressRowsRefsTable(_$WalletDatabase db) => MultiTypedResultKey.fromTable(
    db.addressRows,
    aliasName: 'account_rows__id__address_rows__account_id',
  );

  $$AddressRowsTableProcessedTableManager get addressRowsRefs {
    final manager = $$AddressRowsTableTableManager(
      $_db,
      $_db.addressRows,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_addressRowsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AccountNetworkRowsTable, List<AccountNetworkRow>>
  _accountNetworkRowsRefsTable(_$WalletDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.accountNetworkRows,
        aliasName: 'account_rows__id__account_network_rows__account_id',
      );

  $$AccountNetworkRowsTableProcessedTableManager get accountNetworkRowsRefs {
    final manager = $$AccountNetworkRowsTableTableManager(
      $_db,
      $_db.accountNetworkRows,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _accountNetworkRowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountRowsTableFilterComposer
    extends Composer<_$WalletDatabase, $AccountRowsTable> {
  $$AccountRowsTableFilterComposer({
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

  ColumnFilters<String> get chainFamily => $composableBuilder(
    column: $table.chainFamily,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coinType => $composableBuilder(
    column: $table.coinType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accountIndex => $composableBuilder(
    column: $table.accountIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addressFormat => $composableBuilder(
    column: $table.addressFormat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get derivationProfile => $composableBuilder(
    column: $table.derivationProfile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WalletRowsTableFilterComposer get walletId {
    final $$WalletRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.walletRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletRowsTableFilterComposer(
            $db: $db,
            $table: $db.walletRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> addressRowsRefs(
    Expression<bool> Function($$AddressRowsTableFilterComposer f) f,
  ) {
    final $$AddressRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.addressRows,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AddressRowsTableFilterComposer(
            $db: $db,
            $table: $db.addressRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> accountNetworkRowsRefs(
    Expression<bool> Function($$AccountNetworkRowsTableFilterComposer f) f,
  ) {
    final $$AccountNetworkRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountNetworkRows,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountNetworkRowsTableFilterComposer(
            $db: $db,
            $table: $db.accountNetworkRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountRowsTableOrderingComposer
    extends Composer<_$WalletDatabase, $AccountRowsTable> {
  $$AccountRowsTableOrderingComposer({
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

  ColumnOrderings<String> get chainFamily => $composableBuilder(
    column: $table.chainFamily,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coinType => $composableBuilder(
    column: $table.coinType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accountIndex => $composableBuilder(
    column: $table.accountIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addressFormat => $composableBuilder(
    column: $table.addressFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get derivationProfile => $composableBuilder(
    column: $table.derivationProfile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WalletRowsTableOrderingComposer get walletId {
    final $$WalletRowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.walletRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletRowsTableOrderingComposer(
            $db: $db,
            $table: $db.walletRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountRowsTableAnnotationComposer
    extends Composer<_$WalletDatabase, $AccountRowsTable> {
  $$AccountRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get chainFamily => $composableBuilder(
    column: $table.chainFamily,
    builder: (column) => column,
  );

  GeneratedColumn<int> get coinType =>
      $composableBuilder(column: $table.coinType, builder: (column) => column);

  GeneratedColumn<int> get accountIndex => $composableBuilder(
    column: $table.accountIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get addressFormat => $composableBuilder(
    column: $table.addressFormat,
    builder: (column) => column,
  );

  GeneratedColumn<String> get derivationProfile => $composableBuilder(
    column: $table.derivationProfile,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WalletRowsTableAnnotationComposer get walletId {
    final $$WalletRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.walletRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.walletRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> addressRowsRefs<T extends Object>(
    Expression<T> Function($$AddressRowsTableAnnotationComposer a) f,
  ) {
    final $$AddressRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.addressRows,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AddressRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.addressRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> accountNetworkRowsRefs<T extends Object>(
    Expression<T> Function($$AccountNetworkRowsTableAnnotationComposer a) f,
  ) {
    final $$AccountNetworkRowsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.accountNetworkRows,
          getReferencedColumn: (t) => t.accountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AccountNetworkRowsTableAnnotationComposer(
                $db: $db,
                $table: $db.accountNetworkRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AccountRowsTableTableManager
    extends
        RootTableManager<
          _$WalletDatabase,
          $AccountRowsTable,
          AccountRow,
          $$AccountRowsTableFilterComposer,
          $$AccountRowsTableOrderingComposer,
          $$AccountRowsTableAnnotationComposer,
          $$AccountRowsTableCreateCompanionBuilder,
          $$AccountRowsTableUpdateCompanionBuilder,
          (AccountRow, $$AccountRowsTableReferences),
          AccountRow,
          PrefetchHooks Function({
            bool walletId,
            bool addressRowsRefs,
            bool accountNetworkRowsRefs,
          })
        > {
  $$AccountRowsTableTableManager(_$WalletDatabase db, $AccountRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> walletId = const Value.absent(),
                Value<String> chainFamily = const Value.absent(),
                Value<int> coinType = const Value.absent(),
                Value<int> accountIndex = const Value.absent(),
                Value<String> addressFormat = const Value.absent(),
                Value<String> derivationProfile = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountRowsCompanion(
                id: id,
                walletId: walletId,
                chainFamily: chainFamily,
                coinType: coinType,
                accountIndex: accountIndex,
                addressFormat: addressFormat,
                derivationProfile: derivationProfile,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String walletId,
                required String chainFamily,
                required int coinType,
                Value<int> accountIndex = const Value.absent(),
                required String addressFormat,
                required String derivationProfile,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AccountRowsCompanion.insert(
                id: id,
                walletId: walletId,
                chainFamily: chainFamily,
                coinType: coinType,
                accountIndex: accountIndex,
                addressFormat: addressFormat,
                derivationProfile: derivationProfile,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountRowsTable, AccountRow>(table),
                  $$AccountRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                walletId = false,
                addressRowsRefs = false,
                accountNetworkRowsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (addressRowsRefs) db.addressRows,
                    if (accountNetworkRowsRefs) db.accountNetworkRows,
                  ],
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
                        if (walletId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.walletId,
                                    referencedTable:
                                        $$AccountRowsTableReferences
                                            ._walletIdTable(db),
                                    referencedColumn:
                                        $$AccountRowsTableReferences
                                            ._walletIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (addressRowsRefs)
                        await $_getPrefetchedData<
                          AccountRow,
                          $AccountRowsTable,
                          AddressRow
                        >(
                          currentTable: table,
                          referencedTable: $$AccountRowsTableReferences
                              ._addressRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountRowsTableReferences(
                                db,
                                table,
                                p0,
                              ).addressRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (accountNetworkRowsRefs)
                        await $_getPrefetchedData<
                          AccountRow,
                          $AccountRowsTable,
                          AccountNetworkRow
                        >(
                          currentTable: table,
                          referencedTable: $$AccountRowsTableReferences
                              ._accountNetworkRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountRowsTableReferences(
                                db,
                                table,
                                p0,
                              ).accountNetworkRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$WalletDatabase,
      $AccountRowsTable,
      AccountRow,
      $$AccountRowsTableFilterComposer,
      $$AccountRowsTableOrderingComposer,
      $$AccountRowsTableAnnotationComposer,
      $$AccountRowsTableCreateCompanionBuilder,
      $$AccountRowsTableUpdateCompanionBuilder,
      (AccountRow, $$AccountRowsTableReferences),
      AccountRow,
      PrefetchHooks Function({
        bool walletId,
        bool addressRowsRefs,
        bool accountNetworkRowsRefs,
      })
    >;
typedef $$AddressRowsTableCreateCompanionBuilder =
    AddressRowsCompanion Function({
      required String id,
      required String accountId,
      Value<String> derivationPath,
      Value<int?> changeIndex,
      Value<int?> addressIndex,
      required String address,
      required String addressNormalized,
      Value<bool> isPrimary,
      Value<int> rowid,
    });
typedef $$AddressRowsTableUpdateCompanionBuilder =
    AddressRowsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> derivationPath,
      Value<int?> changeIndex,
      Value<int?> addressIndex,
      Value<String> address,
      Value<String> addressNormalized,
      Value<bool> isPrimary,
      Value<int> rowid,
    });

final class $$AddressRowsTableReferences
    extends BaseReferences<_$WalletDatabase, $AddressRowsTable, AddressRow> {
  $$AddressRowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountRowsTable _accountIdTable(_$WalletDatabase db) =>
      db.accountRows.createAlias('address_rows__account_id__account_rows__id');

  $$AccountRowsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountRowsTableTableManager(
      $_db,
      $_db.accountRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AddressRowsTableFilterComposer
    extends Composer<_$WalletDatabase, $AddressRowsTable> {
  $$AddressRowsTableFilterComposer({
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

  ColumnFilters<String> get derivationPath => $composableBuilder(
    column: $table.derivationPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changeIndex => $composableBuilder(
    column: $table.changeIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addressIndex => $composableBuilder(
    column: $table.addressIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addressNormalized => $composableBuilder(
    column: $table.addressNormalized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountRowsTableFilterComposer get accountId {
    final $$AccountRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accountRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountRowsTableFilterComposer(
            $db: $db,
            $table: $db.accountRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AddressRowsTableOrderingComposer
    extends Composer<_$WalletDatabase, $AddressRowsTable> {
  $$AddressRowsTableOrderingComposer({
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

  ColumnOrderings<String> get derivationPath => $composableBuilder(
    column: $table.derivationPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changeIndex => $composableBuilder(
    column: $table.changeIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addressIndex => $composableBuilder(
    column: $table.addressIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addressNormalized => $composableBuilder(
    column: $table.addressNormalized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountRowsTableOrderingComposer get accountId {
    final $$AccountRowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accountRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountRowsTableOrderingComposer(
            $db: $db,
            $table: $db.accountRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AddressRowsTableAnnotationComposer
    extends Composer<_$WalletDatabase, $AddressRowsTable> {
  $$AddressRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get derivationPath => $composableBuilder(
    column: $table.derivationPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get changeIndex => $composableBuilder(
    column: $table.changeIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addressIndex => $composableBuilder(
    column: $table.addressIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get addressNormalized => $composableBuilder(
    column: $table.addressNormalized,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  $$AccountRowsTableAnnotationComposer get accountId {
    final $$AccountRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accountRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.accountRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AddressRowsTableTableManager
    extends
        RootTableManager<
          _$WalletDatabase,
          $AddressRowsTable,
          AddressRow,
          $$AddressRowsTableFilterComposer,
          $$AddressRowsTableOrderingComposer,
          $$AddressRowsTableAnnotationComposer,
          $$AddressRowsTableCreateCompanionBuilder,
          $$AddressRowsTableUpdateCompanionBuilder,
          (AddressRow, $$AddressRowsTableReferences),
          AddressRow,
          PrefetchHooks Function({bool accountId})
        > {
  $$AddressRowsTableTableManager(_$WalletDatabase db, $AddressRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AddressRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AddressRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AddressRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> derivationPath = const Value.absent(),
                Value<int?> changeIndex = const Value.absent(),
                Value<int?> addressIndex = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> addressNormalized = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AddressRowsCompanion(
                id: id,
                accountId: accountId,
                derivationPath: derivationPath,
                changeIndex: changeIndex,
                addressIndex: addressIndex,
                address: address,
                addressNormalized: addressNormalized,
                isPrimary: isPrimary,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                Value<String> derivationPath = const Value.absent(),
                Value<int?> changeIndex = const Value.absent(),
                Value<int?> addressIndex = const Value.absent(),
                required String address,
                required String addressNormalized,
                Value<bool> isPrimary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AddressRowsCompanion.insert(
                id: id,
                accountId: accountId,
                derivationPath: derivationPath,
                changeIndex: changeIndex,
                addressIndex: addressIndex,
                address: address,
                addressNormalized: addressNormalized,
                isPrimary: isPrimary,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AddressRowsTable, AddressRow>(table),
                  $$AddressRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
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
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$AddressRowsTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$AddressRowsTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$AddressRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$WalletDatabase,
      $AddressRowsTable,
      AddressRow,
      $$AddressRowsTableFilterComposer,
      $$AddressRowsTableOrderingComposer,
      $$AddressRowsTableAnnotationComposer,
      $$AddressRowsTableCreateCompanionBuilder,
      $$AddressRowsTableUpdateCompanionBuilder,
      (AddressRow, $$AddressRowsTableReferences),
      AddressRow,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$NetworkRowsTableCreateCompanionBuilder =
    NetworkRowsCompanion Function({
      required String id,
      required String chainFamily,
      required String displayName,
      Value<int> rowid,
    });
typedef $$NetworkRowsTableUpdateCompanionBuilder =
    NetworkRowsCompanion Function({
      Value<String> id,
      Value<String> chainFamily,
      Value<String> displayName,
      Value<int> rowid,
    });

final class $$NetworkRowsTableReferences
    extends BaseReferences<_$WalletDatabase, $NetworkRowsTable, NetworkRow> {
  $$NetworkRowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AccountNetworkRowsTable, List<AccountNetworkRow>>
  _accountNetworkRowsRefsTable(_$WalletDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.accountNetworkRows,
        aliasName: 'network_rows__id__account_network_rows__network_id',
      );

  $$AccountNetworkRowsTableProcessedTableManager get accountNetworkRowsRefs {
    final manager = $$AccountNetworkRowsTableTableManager(
      $_db,
      $_db.accountNetworkRows,
    ).filter((f) => f.networkId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _accountNetworkRowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NetworkRowsTableFilterComposer
    extends Composer<_$WalletDatabase, $NetworkRowsTable> {
  $$NetworkRowsTableFilterComposer({
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

  ColumnFilters<String> get chainFamily => $composableBuilder(
    column: $table.chainFamily,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> accountNetworkRowsRefs(
    Expression<bool> Function($$AccountNetworkRowsTableFilterComposer f) f,
  ) {
    final $$AccountNetworkRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountNetworkRows,
      getReferencedColumn: (t) => t.networkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountNetworkRowsTableFilterComposer(
            $db: $db,
            $table: $db.accountNetworkRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NetworkRowsTableOrderingComposer
    extends Composer<_$WalletDatabase, $NetworkRowsTable> {
  $$NetworkRowsTableOrderingComposer({
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

  ColumnOrderings<String> get chainFamily => $composableBuilder(
    column: $table.chainFamily,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NetworkRowsTableAnnotationComposer
    extends Composer<_$WalletDatabase, $NetworkRowsTable> {
  $$NetworkRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get chainFamily => $composableBuilder(
    column: $table.chainFamily,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  Expression<T> accountNetworkRowsRefs<T extends Object>(
    Expression<T> Function($$AccountNetworkRowsTableAnnotationComposer a) f,
  ) {
    final $$AccountNetworkRowsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.accountNetworkRows,
          getReferencedColumn: (t) => t.networkId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AccountNetworkRowsTableAnnotationComposer(
                $db: $db,
                $table: $db.accountNetworkRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$NetworkRowsTableTableManager
    extends
        RootTableManager<
          _$WalletDatabase,
          $NetworkRowsTable,
          NetworkRow,
          $$NetworkRowsTableFilterComposer,
          $$NetworkRowsTableOrderingComposer,
          $$NetworkRowsTableAnnotationComposer,
          $$NetworkRowsTableCreateCompanionBuilder,
          $$NetworkRowsTableUpdateCompanionBuilder,
          (NetworkRow, $$NetworkRowsTableReferences),
          NetworkRow,
          PrefetchHooks Function({bool accountNetworkRowsRefs})
        > {
  $$NetworkRowsTableTableManager(_$WalletDatabase db, $NetworkRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NetworkRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NetworkRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NetworkRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> chainFamily = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NetworkRowsCompanion(
                id: id,
                chainFamily: chainFamily,
                displayName: displayName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String chainFamily,
                required String displayName,
                Value<int> rowid = const Value.absent(),
              }) => NetworkRowsCompanion.insert(
                id: id,
                chainFamily: chainFamily,
                displayName: displayName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NetworkRowsTable, NetworkRow>(table),
                  $$NetworkRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountNetworkRowsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (accountNetworkRowsRefs) db.accountNetworkRows,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (accountNetworkRowsRefs)
                    await $_getPrefetchedData<
                      NetworkRow,
                      $NetworkRowsTable,
                      AccountNetworkRow
                    >(
                      currentTable: table,
                      referencedTable: $$NetworkRowsTableReferences
                          ._accountNetworkRowsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$NetworkRowsTableReferences(
                            db,
                            table,
                            p0,
                          ).accountNetworkRowsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.networkId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$NetworkRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$WalletDatabase,
      $NetworkRowsTable,
      NetworkRow,
      $$NetworkRowsTableFilterComposer,
      $$NetworkRowsTableOrderingComposer,
      $$NetworkRowsTableAnnotationComposer,
      $$NetworkRowsTableCreateCompanionBuilder,
      $$NetworkRowsTableUpdateCompanionBuilder,
      (NetworkRow, $$NetworkRowsTableReferences),
      NetworkRow,
      PrefetchHooks Function({bool accountNetworkRowsRefs})
    >;
typedef $$AccountNetworkRowsTableCreateCompanionBuilder =
    AccountNetworkRowsCompanion Function({
      required String accountId,
      required String networkId,
      Value<bool> enabled,
      Value<int> rowid,
    });
typedef $$AccountNetworkRowsTableUpdateCompanionBuilder =
    AccountNetworkRowsCompanion Function({
      Value<String> accountId,
      Value<String> networkId,
      Value<bool> enabled,
      Value<int> rowid,
    });

final class $$AccountNetworkRowsTableReferences
    extends
        BaseReferences<
          _$WalletDatabase,
          $AccountNetworkRowsTable,
          AccountNetworkRow
        > {
  $$AccountNetworkRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccountRowsTable _accountIdTable(_$WalletDatabase db) => db
      .accountRows
      .createAlias('account_network_rows__account_id__account_rows__id');

  $$AccountRowsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountRowsTableTableManager(
      $_db,
      $_db.accountRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $NetworkRowsTable _networkIdTable(_$WalletDatabase db) => db
      .networkRows
      .createAlias('account_network_rows__network_id__network_rows__id');

  $$NetworkRowsTableProcessedTableManager get networkId {
    final $_column = $_itemColumn<String>('network_id')!;

    final manager = $$NetworkRowsTableTableManager(
      $_db,
      $_db.networkRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_networkIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AccountNetworkRowsTableFilterComposer
    extends Composer<_$WalletDatabase, $AccountNetworkRowsTable> {
  $$AccountNetworkRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountRowsTableFilterComposer get accountId {
    final $$AccountRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accountRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountRowsTableFilterComposer(
            $db: $db,
            $table: $db.accountRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NetworkRowsTableFilterComposer get networkId {
    final $$NetworkRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.networkId,
      referencedTable: $db.networkRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NetworkRowsTableFilterComposer(
            $db: $db,
            $table: $db.networkRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountNetworkRowsTableOrderingComposer
    extends Composer<_$WalletDatabase, $AccountNetworkRowsTable> {
  $$AccountNetworkRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountRowsTableOrderingComposer get accountId {
    final $$AccountRowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accountRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountRowsTableOrderingComposer(
            $db: $db,
            $table: $db.accountRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NetworkRowsTableOrderingComposer get networkId {
    final $$NetworkRowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.networkId,
      referencedTable: $db.networkRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NetworkRowsTableOrderingComposer(
            $db: $db,
            $table: $db.networkRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountNetworkRowsTableAnnotationComposer
    extends Composer<_$WalletDatabase, $AccountNetworkRowsTable> {
  $$AccountNetworkRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  $$AccountRowsTableAnnotationComposer get accountId {
    final $$AccountRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accountRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.accountRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NetworkRowsTableAnnotationComposer get networkId {
    final $$NetworkRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.networkId,
      referencedTable: $db.networkRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NetworkRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.networkRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountNetworkRowsTableTableManager
    extends
        RootTableManager<
          _$WalletDatabase,
          $AccountNetworkRowsTable,
          AccountNetworkRow,
          $$AccountNetworkRowsTableFilterComposer,
          $$AccountNetworkRowsTableOrderingComposer,
          $$AccountNetworkRowsTableAnnotationComposer,
          $$AccountNetworkRowsTableCreateCompanionBuilder,
          $$AccountNetworkRowsTableUpdateCompanionBuilder,
          (AccountNetworkRow, $$AccountNetworkRowsTableReferences),
          AccountNetworkRow,
          PrefetchHooks Function({bool accountId, bool networkId})
        > {
  $$AccountNetworkRowsTableTableManager(
    _$WalletDatabase db,
    $AccountNetworkRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountNetworkRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountNetworkRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountNetworkRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> networkId = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountNetworkRowsCompanion(
                accountId: accountId,
                networkId: networkId,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String networkId,
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountNetworkRowsCompanion.insert(
                accountId: accountId,
                networkId: networkId,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountNetworkRowsTable, AccountNetworkRow>(
                    table,
                  ),
                  $$AccountNetworkRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false, networkId = false}) {
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
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable:
                                    $$AccountNetworkRowsTableReferences
                                        ._accountIdTable(db),
                                referencedColumn:
                                    $$AccountNetworkRowsTableReferences
                                        ._accountIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (networkId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.networkId,
                                referencedTable:
                                    $$AccountNetworkRowsTableReferences
                                        ._networkIdTable(db),
                                referencedColumn:
                                    $$AccountNetworkRowsTableReferences
                                        ._networkIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$AccountNetworkRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$WalletDatabase,
      $AccountNetworkRowsTable,
      AccountNetworkRow,
      $$AccountNetworkRowsTableFilterComposer,
      $$AccountNetworkRowsTableOrderingComposer,
      $$AccountNetworkRowsTableAnnotationComposer,
      $$AccountNetworkRowsTableCreateCompanionBuilder,
      $$AccountNetworkRowsTableUpdateCompanionBuilder,
      (AccountNetworkRow, $$AccountNetworkRowsTableReferences),
      AccountNetworkRow,
      PrefetchHooks Function({bool accountId, bool networkId})
    >;
typedef $$BackupStatusRowsTableCreateCompanionBuilder =
    BackupStatusRowsCompanion Function({
      required String walletId,
      Value<String> state,
      Value<String?> remoteChecksum,
      Value<DateTime?> lastVerifiedAt,
      Value<int> rowid,
    });
typedef $$BackupStatusRowsTableUpdateCompanionBuilder =
    BackupStatusRowsCompanion Function({
      Value<String> walletId,
      Value<String> state,
      Value<String?> remoteChecksum,
      Value<DateTime?> lastVerifiedAt,
      Value<int> rowid,
    });

final class $$BackupStatusRowsTableReferences
    extends
        BaseReferences<
          _$WalletDatabase,
          $BackupStatusRowsTable,
          BackupStatusRow
        > {
  $$BackupStatusRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WalletRowsTable _walletIdTable(_$WalletDatabase db) => db.walletRows
      .createAlias('backup_status_rows__wallet_id__wallet_rows__id');

  $$WalletRowsTableProcessedTableManager get walletId {
    final $_column = $_itemColumn<String>('wallet_id')!;

    final manager = $$WalletRowsTableTableManager(
      $_db,
      $_db.walletRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BackupStatusRowsTableFilterComposer
    extends Composer<_$WalletDatabase, $BackupStatusRowsTable> {
  $$BackupStatusRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteChecksum => $composableBuilder(
    column: $table.remoteChecksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WalletRowsTableFilterComposer get walletId {
    final $$WalletRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.walletRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletRowsTableFilterComposer(
            $db: $db,
            $table: $db.walletRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BackupStatusRowsTableOrderingComposer
    extends Composer<_$WalletDatabase, $BackupStatusRowsTable> {
  $$BackupStatusRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteChecksum => $composableBuilder(
    column: $table.remoteChecksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WalletRowsTableOrderingComposer get walletId {
    final $$WalletRowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.walletRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletRowsTableOrderingComposer(
            $db: $db,
            $table: $db.walletRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BackupStatusRowsTableAnnotationComposer
    extends Composer<_$WalletDatabase, $BackupStatusRowsTable> {
  $$BackupStatusRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get remoteChecksum => $composableBuilder(
    column: $table.remoteChecksum,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => column,
  );

  $$WalletRowsTableAnnotationComposer get walletId {
    final $$WalletRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.walletRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.walletRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BackupStatusRowsTableTableManager
    extends
        RootTableManager<
          _$WalletDatabase,
          $BackupStatusRowsTable,
          BackupStatusRow,
          $$BackupStatusRowsTableFilterComposer,
          $$BackupStatusRowsTableOrderingComposer,
          $$BackupStatusRowsTableAnnotationComposer,
          $$BackupStatusRowsTableCreateCompanionBuilder,
          $$BackupStatusRowsTableUpdateCompanionBuilder,
          (BackupStatusRow, $$BackupStatusRowsTableReferences),
          BackupStatusRow,
          PrefetchHooks Function({bool walletId})
        > {
  $$BackupStatusRowsTableTableManager(
    _$WalletDatabase db,
    $BackupStatusRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BackupStatusRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BackupStatusRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BackupStatusRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> walletId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> remoteChecksum = const Value.absent(),
                Value<DateTime?> lastVerifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BackupStatusRowsCompanion(
                walletId: walletId,
                state: state,
                remoteChecksum: remoteChecksum,
                lastVerifiedAt: lastVerifiedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String walletId,
                Value<String> state = const Value.absent(),
                Value<String?> remoteChecksum = const Value.absent(),
                Value<DateTime?> lastVerifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BackupStatusRowsCompanion.insert(
                walletId: walletId,
                state: state,
                remoteChecksum: remoteChecksum,
                lastVerifiedAt: lastVerifiedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BackupStatusRowsTable, BackupStatusRow>(table),
                  $$BackupStatusRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({walletId = false}) {
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
                    if (walletId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.walletId,
                                referencedTable:
                                    $$BackupStatusRowsTableReferences
                                        ._walletIdTable(db),
                                referencedColumn:
                                    $$BackupStatusRowsTableReferences
                                        ._walletIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$BackupStatusRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$WalletDatabase,
      $BackupStatusRowsTable,
      BackupStatusRow,
      $$BackupStatusRowsTableFilterComposer,
      $$BackupStatusRowsTableOrderingComposer,
      $$BackupStatusRowsTableAnnotationComposer,
      $$BackupStatusRowsTableCreateCompanionBuilder,
      $$BackupStatusRowsTableUpdateCompanionBuilder,
      (BackupStatusRow, $$BackupStatusRowsTableReferences),
      BackupStatusRow,
      PrefetchHooks Function({bool walletId})
    >;

class $WalletDatabaseManager {
  final _$WalletDatabase _db;
  $WalletDatabaseManager(this._db);
  $$WalletRowsTableTableManager get walletRows =>
      $$WalletRowsTableTableManager(_db, _db.walletRows);
  $$AccountRowsTableTableManager get accountRows =>
      $$AccountRowsTableTableManager(_db, _db.accountRows);
  $$AddressRowsTableTableManager get addressRows =>
      $$AddressRowsTableTableManager(_db, _db.addressRows);
  $$NetworkRowsTableTableManager get networkRows =>
      $$NetworkRowsTableTableManager(_db, _db.networkRows);
  $$AccountNetworkRowsTableTableManager get accountNetworkRows =>
      $$AccountNetworkRowsTableTableManager(_db, _db.accountNetworkRows);
  $$BackupStatusRowsTableTableManager get backupStatusRows =>
      $$BackupStatusRowsTableTableManager(_db, _db.backupStatusRows);
}
