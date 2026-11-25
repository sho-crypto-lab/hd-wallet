import 'package:flutter/material.dart';
import '../models/home_data.dart';
import '../widgets/asset_list.dart';
import '../widgets/home_header.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/total_balance.dart';
import '../widgets/wallet_actions.dart';

/// 通貨に依存しないホーム。取得・換算・鍵管理は外部に任せる。
/// 未接続の操作は無効表示にし、接続時だけコールバックを実行する。
class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    this.initialData = const HomeData(),
    this.loadData,
    this.onSwitchWallet,
    this.onScan,
    this.onSend,
    this.onReceive,
    this.onHistory,
    this.onSettings,
    this.onOpenAsset,
  });

  final HomeData initialData;
  final Future<HomeData> Function()? loadData;
  final VoidCallback? onSwitchWallet;
  final VoidCallback? onScan;
  final VoidCallback? onSend;
  final VoidCallback? onReceive;
  final VoidCallback? onHistory;
  final VoidCallback? onSettings;
  final void Function(HomeAsset asset, bool hidden)? onOpenAsset;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late HomeData _data;
  bool _hidden = false;
  bool _loading = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    if (widget.loadData != null) _load();
  }

  @override
  void didUpdateWidget(covariant HomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadData != widget.loadData ||
        oldWidget.initialData != widget.initialData) {
      // 切り替え前のウォレットへの応答が、新しい表示を上書きしないようにする。
      _request++;
      _loading = false;
      _data = widget.initialData;
      if (widget.loadData != null) _load();
    }
  }

  Future<void> _load() async {
    final loader = widget.loadData;
    if (loader == null || _loading) return;
    final request = ++_request;
    setState(() {
      _loading = true;
      _data = _data.loading();
    });
    try {
      final data = await loader();
      if (mounted && request == _request) setState(() => _data = data);
    } catch (_) {
      // 取得失敗を0円や「取引なし」へ変換しない。例外の詳細も画面へ出さない。
      if (mounted && request == _request) {
        setState(() => _data = widget.initialData.failed());
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HomeHeader(
                  walletName: _data.walletName,
                  onSwitchWallet: widget.onSwitchWallet,
                  onScan: widget.onScan,
                ),
                const SizedBox(height: 36),
                TotalBalance(
                  balance: _data.totalJpy,
                  hidden: _hidden,
                  onToggle: () => setState(() => _hidden = !_hidden),
                  onRetry: !_loading && widget.loadData != null ? _load : null,
                ),
                const SizedBox(height: 28),
                WalletActions(
                  onSend: widget.onSend,
                  onReceive: widget.onReceive,
                ),
                const SizedBox(height: 40),
                AssetList(
                  assets: _data.assets,
                  hidden: _hidden,
                  onTap: widget.onOpenAsset == null
                      ? null
                      : (asset) => widget.onOpenAsset!(asset, _hidden),
                ),
                const SizedBox(height: 28),
                RecentTransactions(
                  transactions: _data.transactions,
                  hidden: _hidden,
                  onHistory: widget.onHistory,
                ),
                if (!_loading &&
                    widget.loadData != null &&
                    (_data.assets.state == HomeLoadState.error ||
                        _data.transactions.state == HomeLoadState.error))
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _load,
                      child: const Text('データを再取得'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: widget.loadData == null
                ? content
                : RefreshIndicator(onRefresh: _load, child: content),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) widget.onHistory?.call();
          if (index == 2) widget.onSettings?.call();
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            enabled: widget.onHistory != null,
            icon: const Icon(Icons.history),
            label: '取引履歴',
            tooltip: widget.onHistory == null ? '取引履歴（準備中）' : '取引履歴',
          ),
          NavigationDestination(
            enabled: widget.onSettings != null,
            icon: const Icon(Icons.settings_outlined),
            label: '設定',
            tooltip: widget.onSettings == null ? '設定（準備中）' : '設定',
          ),
        ],
      ),
    );
  }
}
