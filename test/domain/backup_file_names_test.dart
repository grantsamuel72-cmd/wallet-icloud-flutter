import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/src/domain/backup_file_names.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

void main() {
  group('backup file names', () {
    test('round-trip wallet ids, including non-ASCII ones', () {
      for (final walletId in <String>['wallet-1', '0xAbC', '钱包 1']) {
        expect(walletIdFromFileName(backupFileNameFor(walletId)), walletId);
      }
    });

    test('stay distinct on case-insensitive file systems', () {
      final upper = backupFileNameFor('Wallet');
      final lower = backupFileNameFor('wallet');

      expect(upper.toLowerCase(), isNot(lower.toLowerCase()));
    });

    test('trim wallet ids consistently', () {
      expect(backupFileNameFor('  wallet-1 '), backupFileNameFor('wallet-1'));
    });

    test('ignore files not created by this package', () {
      expect(walletIdFromFileName('wallet-backup.json'), isNull);
      expect(walletIdFromFileName('wallet-ABCD.json'), isNull);
      expect(walletIdFromFileName('wallet-2077616c6c6574.json'), isNull); // " wallet"
      expect(walletIdFromFileName('wallet-ff.json'), isNull); // invalid UTF-8
    });

    test('reject unusable wallet ids', () {
      expect(() => backupFileNameFor(' '), throwsA(isA<BackupFormatException>()));
      expect(() => backupFileNameFor('a\nb'), throwsA(isA<BackupFormatException>()));
      // Unpaired surrogates would otherwise both encode to U+FFFD and share a file.
      expect(() => backupFileNameFor('w\uD800'), throwsA(isA<BackupFormatException>()));
      expect(
        () => backupFileNameFor('x' * (maxWalletIdLengthInBytes + 1)),
        throwsA(isA<BackupFormatException>()),
      );
      expect(backupFileNameFor('x' * maxWalletIdLengthInBytes).length, lessThan(255));
    });

    // Frozen on purpose: these exact strings name the files already sitting in
    // users' iCloud and Drive accounts. Changing the encoding orphans them, and
    // a round-trip test cannot notice because encode and decode change together.
    test('freeze the encoding so existing cloud files stay reachable', () {
      const vectors = <String, String>{
        'wallet-1': 'wallet-77616c6c65742d31.json',
        'demo-wallet': 'wallet-64656d6f2d77616c6c6574.json',
        '钱包 1': 'wallet-e992b1e58c852031.json',
      };
      vectors.forEach((walletId, fileName) {
        expect(backupFileNameFor(walletId), fileName);
        expect(walletIdFromFileName(fileName), walletId);
      });
    });
  });

  group('assertPlainBackupFileName', () {
    test('rejects names that would address something other than one file', () {
      for (final fileName in <String>['', '   ', '.hidden', 'a/b.json', 'a:b.json']) {
        expect(
          () => assertPlainBackupFileName(fileName),
          throwsA(isA<ArgumentError>()),
          reason: 'should reject "$fileName"',
        );
      }
      expect(
        () => assertPlainBackupFileName('x' * (maxBackupFileNameLengthInBytes + 1)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts every name this package generates', () {
      final fileName = backupFileNameFor('x' * maxWalletIdLengthInBytes);
      expect(assertPlainBackupFileName(fileName), fileName);
    });
  });
}
