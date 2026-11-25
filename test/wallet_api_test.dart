import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hd_wallet/src/core/storage/wallet_storage.dart';
import 'package:hd_wallet/src/wallet/bitcoin/services/bitcoin_wallet_service.dart';
import 'package:hd_wallet/src/wallet/bitcoin/storage/bitcoin_wallet_storage.dart';
import 'support/memory_secure_storage.dart';
import 'package:hd_wallet/src/rust/api/wallet.dart';
import 'package:hd_wallet/src/rust/frb_generated.dart';

const phrase =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

void main() {
  setUpAll(() async {
    final filename = Platform.isMacOS
        ? 'librust_lib_hd_wallet.dylib'
        : Platform.isWindows
        ? 'rust_lib_hd_wallet.dll'
        : 'librust_lib_hd_wallet.so';
    await RustLib.init(
      externalLibrary: ExternalLibrary.open('rust/target/debug/$filename'),
    );
  });
  tearDownAll(RustLib.dispose);

  test(
    'Generates and validates a 12-word phrase through the Rust bridge',
    () async {
      final generated = await generateMnemonic();
      expect(generated.split(' '), hasLength(12));
      expect(await validateMnemonic(phrase: generated), isTrue);
      expect(await validateMnemonic(phrase: 'invalid'), isFalse);
    },
  );

  test('Matches BIP-84 addresses and paths through the Rust bridge', () async {
    for (final entry in [
      (0, 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu'),
      (1, 'bc1qnjg0jd8228aq7egyzacy8cys3knf9xvrerkf9g'),
    ]) {
      final result = await deriveReceiveAddress(
        phrase: phrase,
        passphrase: '',
        network: WalletNetwork.bitcoin,
        account: 0,
        index: entry.$1,
      );
      expect(result.address, entry.$2);
      expect(result.path, "m/84'/0'/0'/0/${entry.$1}");
    }
  });

  test('Preserves network, account, and passphrase settings', () async {
    for (final entry in [
      (WalletNetwork.testnet, 'tb1q'),
      (WalletNetwork.signet, 'tb1q'),
      (WalletNetwork.regtest, 'bcrt1q'),
    ]) {
      final original = await deriveReceiveAddress(
        phrase: phrase,
        passphrase: '',
        network: entry.$1,
        account: 2,
        index: 3,
      );
      final restored = await deriveReceiveAddress(
        phrase: phrase,
        passphrase: '',
        network: entry.$1,
        account: 2,
        index: 3,
      );
      final withPassphrase = await deriveReceiveAddress(
        phrase: phrase,
        passphrase: 'TREZOR',
        network: entry.$1,
        account: 2,
        index: 3,
      );
      expect(original.address, startsWith(entry.$2));
      expect(original.path, "m/84'/1'/2'/0/3");
      expect(restored.address, original.address);
      expect(withPassphrase.address, isNot(original.address));
    }
  });

  test('Propagates invalid phrase and derivation errors to Dart', () async {
    for (final entry in [
      ('invalid', 0, 0),
      (phrase, 0x80000000, 0),
      (phrase, 0, 0x80000000),
    ]) {
      await expectLater(
        deriveReceiveAddress(
          phrase: entry.$1,
          passphrase: '',
          network: WalletNetwork.bitcoin,
          account: entry.$2,
          index: entry.$3,
        ),
        throwsA(isA<String>()),
      );
    }
  });

  test('Creates and reloads a wallet through the real Rust bridge', () async {
    final memory = MemorySecureStorage();
    BitcoinWalletService service() => BitcoinWalletService(
      storage: BitcoinWalletStorage(storage: WalletStorage(storage: memory)),
    );
    final restored = await service().restore(
      phrase: phrase,
      passphrase: '',
      network: WalletNetwork.bitcoin,
      account: 0,
      index: 0,
    );
    expect(
      restored.address.address,
      'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu',
    );
    final loaded = (await service().load())!;
    expect(loaded.address.address, restored.address.address);
    expect(loaded.address.path, "m/84'/0'/0'/0/0");
    final created = await service().create(
      passphrase: 'TREZOR',
      network: WalletNetwork.signet,
      account: 2,
      index: 3,
      replace: true,
    );
    expect(created.wallet.phrase.split(' '), hasLength(12));
    final reloaded = (await service().load())!;
    expect(reloaded.address.address, created.address.address);
    expect(reloaded.wallet.passphrase, 'TREZOR');
    expect(reloaded.account.network, WalletNetwork.signet);
  });
}
