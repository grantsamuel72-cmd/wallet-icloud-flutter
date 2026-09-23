import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/wallet_cloud_backup.dart';

void main() {
  group('exceptions', () {
    test('share one base type so callers can catch everything once', () {
      final all = <Object>[
        const BackupFormatException('m'),
        const BackupIntegrityException('m'),
        BackupNotFoundException('f'),
        BackupConflictException(<String>{'v'}),
        const CloudAuthenticationException('m'),
        const CloudUnavailableException('m'),
        const CloudStorageException('m'),
        const WrongBackupPasswordException(),
        const WeakBackupPasswordException(8),
        const InvalidMnemonicException(),
        const WalletCoreUnavailableException('m'),
      ];

      for (final error in all) {
        expect(error, isA<WalletCloudBackupException>());
        expect(error, isA<Exception>());
      }
    });

    test('toString names the concrete type and message', () {
      expect(
        const CloudStorageException('Timed out.').toString(),
        'CloudStorageException: Timed out.',
      );
    });

    test('keep the underlying cause', () {
      final cause = StateError('native');

      expect(CloudStorageException('m', cause: cause).cause, same(cause));
      expect(BackupNotFoundException('f', cause: cause).cause, same(cause));
      expect(InvalidMnemonicException(cause: cause).cause, same(cause));
    });

    test('carry their structured details', () {
      final notFound = BackupNotFoundException('wallet-1.json');
      final conflict = BackupConflictException(<String>{'v2', 'v3'});
      const weak = WeakBackupPasswordException(10);

      expect(notFound.fileName, 'wallet-1.json');
      expect(notFound.message, contains('wallet-1.json'));
      expect(conflict.unreviewedVersionIds, <String>{'v2', 'v3'});
      expect(conflict.message, allOf(contains('v2'), contains('v3')));
      expect(weak.minLength, 10);
      expect(weak.message, contains('10'));
    });

    test('never need secret input to describe themselves', () {
      expect(const WrongBackupPasswordException().message, 'The backup password is incorrect.');
      expect(const InvalidMnemonicException().message, 'The mnemonic is not a valid BIP39 phrase.');
    });
  });
}
