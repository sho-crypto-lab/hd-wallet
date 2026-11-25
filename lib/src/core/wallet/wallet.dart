/// 通貨に依存しないBIP-39の復元情報。秘密情報をログへ出力しないこと。
class Wallet {
  const Wallet({required this.phrase, required this.passphrase});

  /// 各通貨の鍵を導出する元となるリカバリーフレーズ。
  final String phrase;

  /// BIP-39の追加パスフレーズ。未使用時は空文字列。
  /// アプリのロック用パスワードではなく、異なる値からは別の鍵が生成される。
  final String passphrase;
}
