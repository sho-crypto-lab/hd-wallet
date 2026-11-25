import 'package:hd_wallet/src/rust/api/wallet.dart' as rust;

/// フレーズがBIP-39の検証を通らなかったことを呼び出し元へ通知する。
class InvalidMnemonic implements Exception {}

/// 英語12単語のBIP-39フレーズを生成する。
Future<String> generateMnemonic() => rust.generateMnemonic();

/// BIP-39フレーズの単語数・単語・チェックサムを検証する。
/// 検証に失敗すると[InvalidMnemonic]を投げ、入力フレーズ自体は例外に含めない。
Future<void> validateMnemonic(String phrase) async {
  if (!await rust.validateMnemonic(phrase: phrase)) {
    throw InvalidMnemonic();
  }
}
