import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 端末のセキュアストレージ。保存内容の形式には関与しない。
class SecureStorage {
  const SecureStorage({
    FlutterSecureStorage storage = const FlutterSecureStorage(
      iOptions: IOSOptions(
        accountName: 'hd_wallet',
        // iOSではロック解除中のみ参照でき、他端末へ移行できない設定にする。
        accessibility: KeychainAccessibility.unlocked_this_device,
        // 復元情報をiCloud Keychainへ同期しない。
        synchronizable: false,
      ),
    ),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  /// キーが存在しない場合はnullを返す。読込失敗は例外として伝える。
  Future<String?> read(String key) => _storage.read(key: key);

  /// 指定キーの値を保存・更新する。失敗時に別の保存先へ切り替えない。
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  /// 指定キーだけを削除し、他のセキュアデータには触れない。
  Future<void> delete(String key) => _storage.delete(key: key);
}
