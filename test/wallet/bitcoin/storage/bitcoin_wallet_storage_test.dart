import 'package:flutter_test/flutter_test.dart';
import 'package:hd_wallet/src/rust/api/wallet.dart';
import 'package:hd_wallet/src/wallet/bitcoin/models/bitcoin_account.dart';
import 'package:hd_wallet/src/wallet/bitcoin/storage/bitcoin_wallet_storage.dart';
import 'package:hd_wallet/src/core/wallet/wallet.dart';
import 'package:hd_wallet/src/core/storage/wallet_storage.dart';

import '../../../support/fake_wallet_api.dart';
import '../../../support/memory_secure_storage.dart';

void main() {
  late MemorySecureStorage memory;
  late WalletStorage shared;
  late BitcoinWalletStorage storage;
  const wallet = Wallet(phrase: testPhrase, passphrase: 'TREZOR');
  const account = BitcoinAccount(
    network: WalletNetwork.signet,
    account: 2,
    index: 3,
  );

  setUp(() {
    memory = MemorySecureStorage();
    shared = WalletStorage(storage: memory);
    storage = BitcoinWalletStorage(storage: shared);
  });

  test(
    'Preserves other chain settings when updating the same wallet',
    () async {
      final otherSettings = <String, dynamic>{'network': 'test-network'};
      await shared.write((
        wallet: wallet,
        accounts: {'future-chain': otherSettings},
      ));
      await storage.write((wallet: wallet, account: account));
      final loaded = (await BitcoinWalletStorage(storage: shared).read())!;
      expect(loaded.wallet.phrase, wallet.phrase);
      expect(loaded.wallet.passphrase, wallet.passphrase);
      expect(loaded.account.network, account.network);
      expect(loaded.account.account, 2);
      expect(loaded.account.index, 3);
      expect((await shared.read())!.accounts['future-chain'], otherSettings);
      expect(memory.values, hasLength(1));
    },
  );

  test('Uses Bitcoin defaults when only a shared wallet exists', () async {
    await shared.write((wallet: wallet, accounts: {}));
    final loaded = (await storage.read())!;
    expect(loaded.account.network, WalletNetwork.testnet);
    expect(loaded.account.account, 0);
    expect(loaded.account.index, 0);
  });

  test('Does not carry old settings into a replacement wallet', () async {
    await shared.write((
      wallet: wallet,
      accounts: {'future-chain': <String, dynamic>{}},
    ));
    await storage.write((
      wallet: const Wallet(phrase: otherTestPhrase, passphrase: ''),
      account: account,
    ));
    expect((await shared.read())!.accounts.keys, ['bitcoin']);
  });

  test('Rejects invalid Bitcoin settings without modifying them', () async {
    for (final invalid in [
      {'network': 'unknown', 'account': 0, 'index': 0},
      {'network': 'bitcoin', 'account': -1, 'index': 0},
      {'network': 'bitcoin', 'account': 0, 'index': 0x80000000},
      {'network': 'bitcoin', 'account': 0, 'index': 1.5},
    ]) {
      await shared.write((wallet: wallet, accounts: {'bitcoin': invalid}));
      final original = Map<String, String>.from(memory.values);
      await expectLater(storage.read(), throwsFormatException);
      expect(memory.values, original);
    }
  });
}
