import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hd_wallet/src/core/wallet/wallet.dart';
import 'package:hd_wallet/src/core/storage/wallet_storage.dart';

import '../../support/fake_wallet_api.dart';
import '../../support/memory_secure_storage.dart';

void main() {
  late MemorySecureStorage memory;
  late WalletStorage storage;
  const wallet = Wallet(phrase: testPhrase, passphrase: 'é ＴＲＥＺＯＲ');

  final data = (wallet: wallet, accounts: <String, dynamic>{});

  setUp(() {
    memory = MemorySecureStorage();
    storage = WalletStorage(storage: memory);
  });

  test(
    'Stores one versioned record and restores it through a new instance',
    () async {
      expect(await storage.read(), isNull);
      await storage.write(data);
      expect(memory.values, hasLength(1));
      final record =
          jsonDecode(memory.values.values.single) as Map<String, dynamic>;
      expect(
        record.keys,
        unorderedEquals(['version', 'phrase', 'passphrase', 'accounts']),
      );
      expect(record['version'], 1);
      final loaded = (await WalletStorage(storage: memory).read())!;
      expect(loaded.wallet.phrase, wallet.phrase);
      expect(loaded.wallet.passphrase, wallet.passphrase);
      expect(loaded.accounts, isEmpty);
    },
  );

  test(
    'Rejects corrupt and unknown records without changing the stored value',
    () async {
      await storage.write(data);
      final key = memory.values.keys.single;
      final valid = jsonDecode(memory.values[key]!) as Map<String, dynamic>;
      for (final corrupt in [
        'not-json $testPhrase',
        'null',
        '[]',
        '{}',
        jsonEncode({...valid, 'version': 2}),
        jsonEncode({...valid, 'version': 1.0}),
        jsonEncode({...valid, 'phrase': ''}),
        jsonEncode({...valid, 'passphrase': null}),
        jsonEncode({...valid, 'accounts': []}),
        jsonEncode({
          ...valid,
          'accounts': {'bitcoin': 'invalid'},
        }),
      ]) {
        memory.values[key] = corrupt;
        await expectLater(
          storage.read(),
          throwsA(
            isA<FormatException>().having(
              (error) => error.toString(),
              'safe message',
              isNot(contains(testPhrase)),
            ),
          ),
        );
        expect(memory.values[key], corrupt);
      }
    },
  );

  test('A write failure leaves the previous record intact', () async {
    await storage.write(data);
    final original = Map<String, String>.from(memory.values);
    memory.failWrite = true;
    await expectLater(storage.write(data), throwsStateError);
    expect(memory.values, original);
  });

  test(
    'Deletes only the Bitcoin wallet and preserves unrelated data',
    () async {
      await storage.write(data);
      memory.values['unrelated'] = 'value';
      memory.failDelete = true;
      await expectLater(storage.delete(), throwsStateError);
      expect(await storage.read(), isNotNull);
      memory.failDelete = false;
      await storage.delete();
      expect(await storage.read(), isNull);
      expect(memory.values, {'unrelated': 'value'});
    },
  );
}
