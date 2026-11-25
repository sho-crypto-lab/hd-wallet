import 'package:flutter/material.dart';
import 'package:hd_wallet/app.dart';
import 'package:hd_wallet/src/rust/frb_generated.dart';

Future<void> main() async {
  // 画面の起動時に保存データをRustで検証するため、先にブリッジを初期化する。
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const MyApp());
}
