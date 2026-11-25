import 'package:hd_wallet/src/rust/api/wallet.dart' as rust;
import 'package:hd_wallet/src/core/wallet/wallet.dart';
import 'package:hd_wallet/src/core/wallet/mnemonic.dart' as mnemonic;
import 'package:hd_wallet/src/wallet/bitcoin/models/bitcoin_account.dart';
import 'package:hd_wallet/src/wallet/bitcoin/models/bitcoin_wallet.dart';
import 'package:hd_wallet/src/wallet/bitcoin/storage/bitcoin_wallet_storage.dart';

/// Bitcoinの鍵導出と保存を組み合わせ、画面から呼ぶ操作を提供する。
/// 画面の表示状態や確認ダイアログは扱わない。
class BitcoinWalletService {
  BitcoinWalletService({
    BitcoinWalletStorage storage = const BitcoinWalletStorage(),
  }) : _storage = storage;

  final BitcoinWalletStorage _storage;

  /// 保存済みフレーズを再検証し、保存済みの派生設定からアドレスを再生成する。
  Future<BitcoinWalletSession?> load() async {
    final wallet = await _storage.read();
    return wallet == null ? null : await _derive(wallet);
  }

  /// 新しいフレーズを生成し、アドレス導出と保存が成功した後に結果を返す。
  /// replaceは、画面で既存ウォレットの置き換えを確認した場合に指定する。
  Future<BitcoinWalletSession> create({
    required String passphrase,
    required rust.WalletNetwork network,
    required int account,
    required int index,
    bool replace = false,
  }) async {
    await _storage.checkReplacement(replace);
    final wallet = Wallet(
      phrase: await mnemonic.generateMnemonic(),
      passphrase: passphrase,
    );
    return _save((
      wallet: wallet,
      account: BitcoinAccount(network: network, account: account, index: index),
    ));
  }

  /// 入力されたフレーズとパスフレーズで復元し、指定された派生設定と保存する。
  Future<BitcoinWalletSession> restore({
    required String phrase,
    required String passphrase,
    required rust.WalletNetwork network,
    required int account,
    required int index,
    bool replace = false,
  }) async {
    await _storage.checkReplacement(replace);
    return _save((
      wallet: Wallet(phrase: phrase, passphrase: passphrase),
      account: BitcoinAccount(network: network, account: account, index: index),
    ));
  }

  /// Bitcoin設定だけでなく、共通ウォレットの復元情報ごと端末から削除する。
  Future<void> delete() => _storage.delete();

  Future<BitcoinWalletSession> _save(BitcoinWalletData data) async {
    // 不正なフレーズや導出失敗で既存データを書き換えないよう、保存前に検証する。
    final session = await _derive(data);
    // 保存失敗を成功扱いにしないよう、書き込み完了を待ってから結果を返す。
    await _storage.write(data);
    return session;
  }

  Future<BitcoinWalletSession> _derive(BitcoinWalletData data) async {
    await mnemonic.validateMnemonic(data.wallet.phrase);
    final address = await rust.deriveReceiveAddress(
      phrase: data.wallet.phrase,
      passphrase: data.wallet.passphrase,
      network: data.account.network,
      account: data.account.account,
      index: data.account.index,
    );
    return (wallet: data.wallet, account: data.account, address: address);
  }
}
