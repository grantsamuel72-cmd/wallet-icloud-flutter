import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_cloud_backup/src/domain/canonical_json.dart';

void main() {
  group('canonicalJsonEncode', () {
    test('sorts object keys at every level', () {
      final encoded = canonicalJsonEncode(<String, Object?>{
        'b': 1,
        'a': <String, Object?>{'z': true, 'y': null},
      });

      expect(encoded, '{"a":{"y":null,"z":true},"b":1}');
    });

    test('keeps list order and sorts objects inside lists', () {
      final encoded = canonicalJsonEncode(<Object?>[
        3,
        <String, Object?>{'b': 'x', 'a': 'y'},
        1,
      ]);

      expect(encoded, '[3,{"a":"y","b":"x"},1]');
    });

    test('does not depend on insertion order', () {
      final first = <String, Object?>{
        'one': 1,
        'two': 2,
        'three': <Object?>[1, 2],
      };
      final second = <String, Object?>{
        'three': <Object?>[1, 2],
        'two': 2,
        'one': 1,
      };

      expect(canonicalJsonEncode(first), canonicalJsonEncode(second));
    });

    test('encodes scalars like jsonEncode', () {
      expect(canonicalJsonEncode('é"\\'), r'"é\"\\"');
      expect(canonicalJsonEncode(1.5), '1.5');
      expect(canonicalJsonEncode(null), 'null');
    });
  });
}
