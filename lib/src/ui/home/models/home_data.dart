import 'package:flutter/material.dart';

/// 未接続・読込中・取得済み・取得失敗を区別し、未取得を0として扱わない。
enum HomeLoadState { unavailable, loading, loaded, error }

class HomeSection<T> {
  const HomeSection.unavailable([this.data])
    : state = HomeLoadState.unavailable;
  const HomeSection.loading() : state = HomeLoadState.loading, data = null;
  const HomeSection.loaded(T value)
    : state = HomeLoadState.loaded,
      data = value;
  const HomeSection.error([this.data]) : state = HomeLoadState.error;

  final HomeLoadState state;
  final T? data;
}

/// ホームに渡せる情報だけを定義する。復元情報や鍵を受け取るフィールドは持たない。
class HomeData {
  const HomeData({
    this.walletName = 'マイウォレット',
    this.totalJpy = const HomeSection.unavailable(),
    this.assets = const HomeSection.unavailable(),
    this.transactions = const HomeSection.unavailable(),
  });

  final String walletName;
  final HomeSection<int> totalJpy;
  final HomeSection<List<HomeAsset>> assets;
  final HomeSection<List<HomeTransaction>> transactions;

  HomeData loading() => HomeData(
    walletName: walletName,
    totalJpy: const HomeSection.loading(),
    assets: const HomeSection.loading(),
    transactions: const HomeSection.loading(),
  );

  HomeData failed() => HomeData(
    walletName: walletName,
    totalJpy: const HomeSection.error(),
    assets: HomeSection.error(assets.data),
    transactions: const HomeSection.error(),
  );
}

class HomeAsset {
  const HomeAsset({
    required this.id,
    required this.name,
    required this.symbol,
    this.icon = Icons.token_outlined,
    this.quantity,
    this.jpyValue,
  });

  final String id;
  final String name;
  final String symbol;
  final IconData icon;

  /// 通貨ごとの桁数処理は取得側で行い、正確な10進表記を渡す。
  final String? quantity;
  final int? jpyValue;
}

enum HomeTransactionDirection { sent, received }

enum HomeTransactionStatus { pending, confirmed, failed }

class HomeTransaction {
  const HomeTransaction({
    required this.id,
    required this.direction,
    required this.date,
    required this.quantity,
    required this.symbol,
    required this.status,
  });

  final String id;
  final HomeTransactionDirection direction;
  final DateTime date;
  final String quantity;
  final String symbol;
  final HomeTransactionStatus status;
}
