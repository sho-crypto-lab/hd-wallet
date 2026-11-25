import 'package:hd_wallet/src/rust/api/wallet.dart';
import 'package:hd_wallet/src/rust/frb_generated.dart';

const testPhrase =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
const otherTestPhrase =
    'legal winner thank year wave sausage worth useful legal winner thank yellow';

class FakeWalletApi implements RustLibApi {
  String generatedPhrase = testPhrase;
  String? receivedPhrase;
  String? receivedPassphrase;
  WalletNetwork? receivedNetwork;
  int? receivedAccount;
  int? receivedIndex;
  int generations = 0;
  bool fail = false;

  @override
  Future<String> crateApiWalletGenerateMnemonic() async {
    generations++;
    return generatedPhrase;
  }

  @override
  Future<bool> crateApiWalletValidateMnemonic({required String phrase}) async =>
      phrase == testPhrase || phrase == otherTestPhrase;

  @override
  Future<ReceiveAddress> crateApiWalletDeriveReceiveAddress({
    required String phrase,
    required String passphrase,
    required WalletNetwork network,
    required int account,
    required int index,
  }) async {
    if (fail) throw StateError('derive failed');
    receivedPhrase = phrase;
    receivedPassphrase = passphrase;
    receivedNetwork = network;
    receivedAccount = account;
    receivedIndex = index;
    return const ReceiveAddress(
      address: 'tb1q-test-address',
      path: "m/84'/1'/0'/0/0",
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
