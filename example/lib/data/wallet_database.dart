import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'wallet_database.g.dart';

class WalletRows extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get name => text()();
  TextColumn get secretRef => text().nullable().unique()();
  TextColumn get state => text().withDefault(const Constant('ready'))();
  BoolColumn get requiresBip39Passphrase =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const <String>[
    "CHECK (kind IN ('hd', 'imported_key', 'watch_only'))",
    "CHECK (state IN ('ready', 'deleting', 'needs_restore'))",
    "CHECK ((kind = 'watch_only' AND secret_ref IS NULL) OR (kind <> 'watch_only' AND secret_ref IS NOT NULL))",
  ];
}

class AccountRows extends Table {
  TextColumn get id => text()();
  TextColumn get walletId =>
      text().references(WalletRows, #id, onDelete: KeyAction.cascade)();
  TextColumn get chainFamily => text()();
  IntColumn get coinType => integer()();
  IntColumn get accountIndex => integer().withDefault(const Constant(0))();
  TextColumn get addressFormat => text()();
  TextColumn get derivationProfile => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const <String>[
    'UNIQUE (wallet_id, chain_family)',
  ];
}

class AddressRows extends Table {
  TextColumn get id => text()();
  TextColumn get accountId =>
      text().references(AccountRows, #id, onDelete: KeyAction.cascade)();
  TextColumn get derivationPath => text().withDefault(const Constant(''))();
  IntColumn get changeIndex => integer().nullable()();
  IntColumn get addressIndex => integer().nullable()();
  TextColumn get address => text()();
  TextColumn get addressNormalized => text()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const <String>[
    'UNIQUE (account_id, derivation_path)',
    'UNIQUE (account_id, address_normalized)',
  ];
}

class NetworkRows extends Table {
  TextColumn get id => text()();
  TextColumn get chainFamily => text()();
  TextColumn get displayName => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AccountNetworkRows extends Table {
  TextColumn get accountId =>
      text().references(AccountRows, #id, onDelete: KeyAction.cascade)();
  TextColumn get networkId => text().references(NetworkRows, #id)();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {accountId, networkId};
}

class BackupStatusRows extends Table {
  TextColumn get walletId =>
      text().references(WalletRows, #id, onDelete: KeyAction.cascade)();
  TextColumn get state => text().withDefault(const Constant('none'))();
  TextColumn get remoteChecksum => text().nullable()();
  DateTimeColumn get lastVerifiedAt => dateTime().nullable()();
  TextColumn get scope => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {walletId};

  @override
  List<String> get customConstraints => const <String>[
    "CHECK (state IN ('none', 'verified', 'failed'))",
  ];
}

@DriftDatabase(
  tables: [
    WalletRows,
    AccountRows,
    AddressRows,
    NetworkRows,
    AccountNetworkRows,
    BackupStatusRows,
  ],
)
class WalletDatabase extends _$WalletDatabase {
  WalletDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'wallet_example',
              native: DriftNativeOptions(
                databaseDirectory: () async {
                  final support = await getApplicationSupportDirectory();
                  final directory = Directory(
                    p.join(support.path, 'wallet_local'),
                  );
                  await directory.create(recursive: true);
                  return directory;
                },
              ),
            ),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.addColumn(backupStatusRows, backupStatusRows.scope);
    },
    beforeOpen: (details) async => customStatement('PRAGMA foreign_keys = ON'),
  );
}
