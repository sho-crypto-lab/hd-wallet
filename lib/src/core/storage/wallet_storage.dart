import 'dart:convert';

import 'package:hd_wallet/src/core/storage/secure_storage.dart';
import 'package:hd_wallet/src/core/wallet/wallet.dart';

/// 共通の復元情報と、通貨名をキーにした通貨固有の設定。
/// 設定内部の検証は、それぞれの通貨のStorageが担当する。
typedef StoredWallet = ({Wallet wallet, Map<String, dynamic> accounts});

/// 既存ウォレットの置き換えが明示的に許可されていない場合の例外。
class WalletAlreadyExists implements Exception {}

/// 共通の復元情報と通貨ごとの設定を、1つのKeychainレコードで保存する。
class WalletStorage {
  const WalletStorage({SecureStorage storage = const SecureStorage()})
    : _storage = storage;

  static const _key = 'wallet';
  // 保存形式を変更する際に、旧形式や未対応形式を判別するための番号。
  static const _version = 1;
  final SecureStorage _storage;

  /// 上書き許可がない場合は既存データを確認する。
  /// 読込エラーも伝播させ、「未保存」と誤認して上書きすることを防ぐ。
  Future<void> checkReplacement(bool replace) async {
    if (!replace && await read() != null) throw WalletAlreadyExists();
  }

  /// 未保存の場合だけnullを返す。破損・未対応形式は削除せず例外にする。
  /// ここでは保存形式を検証し、フレーズのBIP-39検証は呼び出し側で行う。
  Future<StoredWallet?> read() async {
    final value = await _storage.read(_key);
    if (value == null) return null;
    try {
      final json = jsonDecode(value);
      if (json is! Map<String, dynamic> ||
          json['version'] is! int ||
          json['version'] != _version ||
          json['phrase'] is! String ||
          (json['phrase'] as String).trim().isEmpty ||
          json['passphrase'] is! String ||
          json['accounts'] is! Map<String, dynamic>) {
        throw const FormatException();
      }
      final accounts = json['accounts'] as Map<String, dynamic>;
      if (accounts.values.any((value) => value is! Map<String, dynamic>)) {
        throw const FormatException();
      }
      return (
        wallet: Wallet(
          phrase: json['phrase'] as String,
          passphrase: json['passphrase'] as String,
        ),
        accounts: accounts,
      );
    } catch (_) {
      // JSONや復元情報をエラーメッセージに含めない。
      throw const FormatException('保存済みウォレットの形式に対応していません。');
    }
  }

  /// 復元情報と通貨設定を1レコードで保存し、両者の保存内容のずれを防ぐ。
  /// seed・秘密鍵・アドレスは保存せず、必要時に復元情報から再生成する。
  Future<void> write(StoredWallet data) async {
    if (data.wallet.phrase.trim().isEmpty ||
        data.accounts.values.any((value) => value is! Map<String, dynamic>)) {
      throw const FormatException('ウォレットの保存内容が不正です。');
    }
    await _storage.write(
      _key,
      jsonEncode({
        'version': _version,
        'phrase': data.wallet.phrase,
        'passphrase': data.wallet.passphrase,
        'accounts': data.accounts,
      }),
    );
  }

  /// 共通の復元情報と全通貨の設定を削除する。他の保存キーは削除しない。
  Future<void> delete() => _storage.delete(_key);
}
