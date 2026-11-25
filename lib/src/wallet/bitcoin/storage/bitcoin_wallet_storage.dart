import 'package:hd_wallet/src/rust/api/wallet.dart';
import 'package:hd_wallet/src/wallet/bitcoin/models/bitcoin_account.dart';
import 'package:hd_wallet/src/wallet/bitcoin/models/bitcoin_wallet.dart';
import 'package:hd_wallet/src/core/storage/wallet_storage.dart';

/// 共通ウォレットに紐づくBitcoin設定の変換・検証。
class BitcoinWalletStorage {
  const BitcoinWalletStorage({WalletStorage storage = const WalletStorage()})
    : _storage = storage;

  final WalletStorage _storage;

  /// 他通貨で作成したウォレットも含め、共通の復元情報の上書き可否を確認する。
  Future<void> checkReplacement(bool replace) =>
      _storage.checkReplacement(replace);

  /// 共通レコードからBitcoin設定を読み、ネットワークと派生番号を検証する。
  Future<BitcoinWalletData?> read() async {
    final data = await _storage.read();
    if (data == null) return null;
    final json = data.accounts['bitcoin'];
    // 他通貨から作成された共通ウォレットにもBitcoinの初期設定を適用できる。
    if (json == null) {
      return (wallet: data.wallet, account: const BitcoinAccount());
    }
    try {
      if (json is! Map<String, dynamic> ||
          json['network'] is! String ||
          !_isValidIndex(json['account']) ||
          !_isValidIndex(json['index'])) {
        throw const FormatException();
      }
      return (
        wallet: data.wallet,
        account: BitcoinAccount(
          network: WalletNetwork.values.byName(json['network'] as String),
          account: json['account'] as int,
          index: json['index'] as int,
        ),
      );
    } catch (_) {
      throw const FormatException('保存済みBitcoin設定が不正です。');
    }
  }

  /// 同じ復元情報の更新では他通貨の設定を保持し、別の復元情報では引き継がない。
  Future<void> write(BitcoinWalletData data) async {
    if (!_isValidIndex(data.account.account) ||
        !_isValidIndex(data.account.index)) {
      throw const FormatException('Bitcoinの派生設定が不正です。');
    }
    final stored = await _storage.read();
    final sameWallet =
        stored != null &&
        stored.wallet.phrase == data.wallet.phrase &&
        stored.wallet.passphrase == data.wallet.passphrase;
    // 同じウォレットのBitcoin設定を更新するときは、他通貨の設定を保持する。
    await _storage.write((
      wallet: data.wallet,
      accounts: {
        if (sameWallet) ...stored.accounts,
        'bitcoin': <String, dynamic>{
          'network': data.account.network.name,
          'account': data.account.account,
          'index': data.account.index,
        },
      },
    ));
  }

  /// 共通ウォレット全体の削除。Bitcoin設定だけの削除ではない。
  Future<void> delete() => _storage.delete();

  static bool _isValidIndex(Object? value) =>
      value is int && value >= 0 && value < 0x80000000;
}
