import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup_example/data/local_wallet_password.dart';
import 'package:wallet_cloud_backup_example/data/wallet_secret_store.dart';

class _Secrets implements WalletSecretStore {
  final values = <String, String>{};

  @override
  Future<void> write(String reference, String secret) async =>
      values[reference] = secret;

  @override
  Future<String?> read(String reference) async => values[reference];

  @override
  Future<bool> contains(String reference) async =>
      values.containsKey(reference);

  @override
  Future<void> delete(String reference) async => values.remove(reference);
}

void main() {
  test('stores a salted verifier and checks the local password', () async {
    final secrets = _Secrets();
    final gate = LocalWalletPassword(secrets, random: Random(12));
    expect(await gate.isConfigured(), isFalse);
    await expectLater(gate.set('short'), throwsA(isA<FormatException>()));
    await gate.set('local wallet password');
    expect(await gate.isConfigured(), isTrue);
    expect(
      secrets.values.values.single,
      isNot(contains('local wallet password')),
    );
    expect(await gate.verify('wrong password'), isFalse);
    expect(await gate.verify('local wallet password'), isTrue);
    await expectLater(gate.set('another password'), throwsA(isA<StateError>()));
  });
}
