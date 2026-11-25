import 'package:hd_wallet/src/core/wallet/wallet.dart';
import 'package:hd_wallet/src/rust/api/wallet.dart';
import 'bitcoin_account.dart';

/// 共通の復元情報とBitcoin設定を組み合わせた、保存・鍵導出への入力。
typedef BitcoinWalletData = ({Wallet wallet, BitcoinAccount account});

/// 検証・鍵導出が完了した結果。アドレスは永続保存せず毎回導出する。
/// 復元情報も含むため、この値全体をログに出力しないこと。
typedef BitcoinWalletSession = ({
  Wallet wallet,
  BitcoinAccount account,
  ReceiveAddress address,
});
