import 'dart:async';

import 'package:hd_wallet/src/core/storage/secure_storage.dart';

class MemorySecureStorage extends SecureStorage {
  final values = <String, String>{};
  bool failRead = false;
  bool failWrite = false;
  bool failDelete = false;
  Completer<void>? writeGate;

  @override
  Future<String?> read(String key) async {
    if (failRead) throw StateError('read failed');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    await writeGate?.future;
    if (failWrite) throw StateError('write failed');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failDelete) throw StateError('delete failed');
    values.remove(key);
  }
}
