import 'package:flutter_test/flutter_test.dart';
import 'package:hd_wallet/src/core/wallet/mnemonic.dart';
import 'package:hd_wallet/src/rust/api/wallet.dart';
import 'package:hd_wallet/src/rust/frb_generated.dart';
import 'package:hd_wallet/src/wallet/bitcoin/services/bitcoin_wallet_service.dart';
import 'package:hd_wallet/src/wallet/bitcoin/storage/bitcoin_wallet_storage.dart';
import 'package:hd_wallet/src/core/storage/wallet_storage.dart';

import '../../../support/fake_wallet_api.dart';
import '../../../support/memory_secure_storage.dart';

void main() {
  late MemorySecureStorage memory;
  late FakeWalletApi api;
  late BitcoinWalletService service;
  BitcoinWalletService newService() => BitcoinWalletService(
    storage: BitcoinWalletStorage(storage: WalletStorage(storage: memory)),
  );

  setUp(() {
    memory = MemorySecureStorage();
    api = FakeWalletApi();
    RustLib.initMock(api: api);
    service = newService();
  });
  tearDown(RustLib.dispose);

  test(
    'Creates, saves, and restores all settings through a new instance',
    () async {
      final created = await service.create(
        passphrase: 'secret',
        network: WalletNetwork.signet,
        account: 2,
        index: 3,
      );
      final loaded = (await newService().load())!;
      expect(loaded.wallet.phrase, created.wallet.phrase);
      expect(loaded.wallet.passphrase, 'secret');
      expect(loaded.account.network, WalletNetwork.signet);
      expect(loaded.account.account, 2);
      expect(loaded.account.index, 3);
      expect(loaded.address.address, created.address.address);
      expect(api.receivedPassphrase, 'secret');
    },
  );

  test(
    'Requires explicit replacement before generating another wallet',
    () async {
      await service.create(
        passphrase: '',
        network: WalletNetwork.testnet,
        account: 0,
        index: 0,
      );
      final original = Map<String, String>.from(memory.values);
      await expectLater(
        service.create(
          passphrase: '',
          network: WalletNetwork.bitcoin,
          account: 0,
          index: 0,
        ),
        throwsA(isA<WalletAlreadyExists>()),
      );
      expect(api.generations, 1);
      expect(memory.values, original);
      api.generatedPhrase = otherTestPhrase;
      await service.create(
        passphrase: '',
        network: WalletNetwork.bitcoin,
        account: 0,
        index: 0,
        replace: true,
      );
      expect((await service.load())!.wallet.phrase, otherTestPhrase);
    },
  );

  test('Does not save invalid phrases or failed address derivations', () async {
    await expectLater(
      service.restore(
        phrase: 'invalid',
        passphrase: '',
        network: WalletNetwork.testnet,
        account: 0,
        index: 0,
      ),
      throwsA(isA<InvalidMnemonic>()),
    );
    expect(memory.values, isEmpty);
    api.fail = true;
    await expectLater(
      service.create(
        passphrase: '',
        network: WalletNetwork.testnet,
        account: 0,
        index: 0,
      ),
      throwsStateError,
    );
    expect(memory.values, isEmpty);
  });

  test('Failed saves leave the original wallet available', () async {
    await service.create(
      passphrase: '',
      network: WalletNetwork.testnet,
      account: 0,
      index: 0,
    );
    final original = Map<String, String>.from(memory.values);
    memory.failWrite = true;
    api.generatedPhrase = otherTestPhrase;
    await expectLater(
      service.create(
        passphrase: '',
        network: WalletNetwork.bitcoin,
        account: 0,
        index: 0,
        replace: true,
      ),
      throwsStateError,
    );
    expect(memory.values, original);
    expect((await service.load())!.wallet.phrase, testPhrase);
  });

  test(
    'Read failures never become an empty wallet or trigger writes',
    () async {
      memory.failRead = true;
      await expectLater(service.load(), throwsStateError);
      await expectLater(
        service.create(
          passphrase: '',
          network: WalletNetwork.testnet,
          account: 0,
          index: 0,
        ),
        throwsStateError,
      );
      expect(api.generations, 0);
      expect(memory.values, isEmpty);
    },
  );
}
