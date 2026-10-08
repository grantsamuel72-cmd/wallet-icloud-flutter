import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:wallet_cloud_backup_example/data/wallet_secret_store.dart';

/// A local password gate for this example's Web3 wallet operations.
/// The verifier stays in device secure storage; no password goes to Drive.
class LocalWalletPassword {
  LocalWalletPassword(this._secrets, {Random? random})
    : _random = random ?? Random.secure();

  static const _reference = 'wallet/local-password-verifier/v1';
  final WalletSecretStore _secrets;
  final Random _random;
  final _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 210000,
    bits: 256,
  );

  Future<bool> isConfigured() => _secrets.contains(_reference);

  Future<void> set(String password) async {
    if (await isConfigured()) throw StateError('本地钱包密码已设置。');
    if (password.runes.length < 8) {
      throw const FormatException('本地钱包密码至少需要 8 位。');
    }
    final salt = List<int>.generate(16, (_) => _random.nextInt(256));
    final key = await _derive(password, salt);
    await _secrets.write(
      _reference,
      jsonEncode(<String, Object>{
        'salt': base64Encode(salt),
        'hash': base64Encode(key),
      }),
    );
  }

  Future<bool> verify(String password) async {
    final raw = await _secrets.read(_reference);
    if (raw == null) return false;
    final record = jsonDecode(raw) as Map<String, dynamic>;
    final salt = base64Decode(record['salt'] as String);
    final expected = base64Decode(record['hash'] as String);
    final actual = await _derive(password, salt);
    if (actual.length != expected.length) return false;
    var difference = 0;
    for (var i = 0; i < actual.length; i++) {
      difference |= actual[i] ^ expected[i];
    }
    return difference == 0;
  }

  Future<List<int>> _derive(String password, List<int> salt) async {
    final key = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return key.extractBytes();
  }
}
