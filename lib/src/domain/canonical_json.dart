import 'dart:convert';

/// Encodes [value] as JSON with object keys sorted recursively.
///
/// Used wherever bytes must be reproducible from the same data: backup
/// checksums and the associated data authenticated by AES-GCM.
String canonicalJsonEncode(Object? value) => jsonEncode(_canonicalize(value));

Object? _canonicalize(Object? value) {
  if (value is Map<String, Object?>) {
    final keys = value.keys.toList()..sort();
    return <String, Object?>{for (final key in keys) key: _canonicalize(value[key])};
  }
  if (value is List<Object?>) {
    return value.map(_canonicalize).toList(growable: false);
  }
  return value;
}
