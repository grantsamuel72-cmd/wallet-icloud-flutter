import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

void main() {
  group('CloudBackupFile', () {
    final file = CloudBackupFile(
      id: 'file-1',
      name: 'wallet-77.json',
      provider: CloudBackupProvider.iCloud,
      createdAt: DateTime.utc(2026),
      modifiedAt: DateTime.utc(2026, 2),
      sizeInBytes: 42,
      hasUnresolvedConflicts: true,
    );

    test('defaults to no wallet id and no conflicts', () {
      const minimal = CloudBackupFile(
        id: 'id',
        name: 'name',
        provider: CloudBackupProvider.googleDrive,
      );

      expect(minimal.walletId, isNull);
      expect(minimal.hasUnresolvedConflicts, isFalse);
      expect(minimal.createdAt, isNull);
    });

    test('withWalletId copies every other field', () {
      final copy = file.withWalletId('w');

      expect(copy.walletId, 'w');
      expect(copy.id, file.id);
      expect(copy.name, file.name);
      expect(copy.provider, file.provider);
      expect(copy.createdAt, file.createdAt);
      expect(copy.modifiedAt, file.modifiedAt);
      expect(copy.sizeInBytes, file.sizeInBytes);
      expect(copy.hasUnresolvedConflicts, isTrue);
      expect(file.walletId, isNull, reason: 'the original is unchanged');
    });
  });

  test('BackupConflictVersion keeps its fields', () {
    final version = BackupConflictVersion(id: 'v1', modifiedAt: DateTime.utc(2026));

    expect(version.id, 'v1');
    expect(version.modifiedAt, DateTime.utc(2026));
  });
}
