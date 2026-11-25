import 'package:hd_wallet/src/rust/api/wallet.dart';

/// Bitcoin固有のネットワークとBIP-84派生設定。
class BitcoinAccount {
  const BitcoinAccount({
    this.network = WalletNetwork.testnet,
    this.account = 0,
    this.index = 0,
  });

  final WalletNetwork network;

  /// BIP-84のアカウント番号。0以上2^31未満。
  final int account;

  /// 受取用ブランチ内のアドレス番号。0以上2^31未満。
  final int index;
}
