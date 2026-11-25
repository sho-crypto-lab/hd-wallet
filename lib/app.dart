import 'package:flutter/material.dart';
import 'package:hd_wallet/src/ui/home/home_theme.dart';
import 'package:hd_wallet/src/ui/home/models/home_data.dart';
import 'package:hd_wallet/src/ui/home/views/home_view.dart';
import 'package:hd_wallet/src/wallet/bitcoin/views/bitcoin_detail_view.dart';

/// アプリ全体のテーマと最初に表示する画面を設定する。
class MyApp extends StatelessWidget {
  const MyApp({super.key, this.home});

  /// 既存画面の単体テストなどで、起動画面を差し替えられる。
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HD Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F7F4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF7931A),
          primary: const Color(0xFF252521),
          onPrimary: Colors.white,
          surface: const Color(0xFFF8F7F4),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.4,
            letterSpacing: -0.8,
          ),
          headlineMedium: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            height: 1.45,
            letterSpacing: -0.5,
          ),
          bodyMedium: TextStyle(fontSize: 15, height: 1.7),
          labelSmall: TextStyle(color: Color(0xFF68685F), fontSize: 12),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F7F4),
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF252521),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            side: const BorderSide(color: Color(0xFFD3D0C8)),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD3D0C8)),
          ),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFE6E2DB)),
      ),
      home: home ?? const _WalletHome(),
    );
  }
}

class _WalletHome extends StatelessWidget {
  const _WalletHome();

  @override
  Widget build(BuildContext context) => Theme(
    data: buildHomeTheme(),
    child: HomeView(
      onOpenAsset: (asset, hidden) {
        if (asset.id != 'bitcoin') return;
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => Theme(
              data: buildHomeTheme(),
              child: BitcoinDetailView(
                quantity: asset.quantity,
                jpyValue: asset.jpyValue,
                initiallyHidden: hidden,
              ),
            ),
          ),
        );
      },
      initialData: const HomeData(
        // 対応資産の情報のみ。残高・評価額・取引の実データは未接続。
        assets: HomeSection.unavailable([
          HomeAsset(
            id: 'bitcoin',
            name: 'Bitcoin',
            symbol: 'BTC',
            icon: Icons.currency_bitcoin,
          ),
        ]),
      ),
    ),
  );
}
