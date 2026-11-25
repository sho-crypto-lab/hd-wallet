import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hd_wallet/src/rust/api/wallet.dart';
import 'package:hd_wallet/src/wallet/bitcoin/models/bitcoin_wallet.dart';
import 'package:hd_wallet/src/wallet/bitcoin/services/bitcoin_wallet_service.dart';
import 'bitcoin_wallet_form_view.dart';
import '../widgets/bitcoin_receive_card.dart';
import '../widgets/bitcoin_settings_sheet.dart';
import '../widgets/bitcoin_welcome.dart';
import '../widgets/wallet_error_message.dart';
import '../widgets/wallet_page_layout.dart';

/// 保存状態に応じて初回画面と受取画面を切り替える。
/// 画面の状態はここで管理し、永続化と鍵導出はServiceに任せる。
class BitcoinWalletView extends StatefulWidget {
  const BitcoinWalletView({super.key, this.service});
  final BitcoinWalletService? service;

  @override
  State<BitcoinWalletView> createState() => _BitcoinWalletViewState();
}

class _BitcoinWalletViewState extends State<BitcoinWalletView> {
  late final BitcoinWalletService _service;
  BitcoinWalletSession? _session;
  bool _busy = true;
  bool _loadFailed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? BitcoinWalletService();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await _service.load();
      if (!mounted) return;
      setState(() {
        _session = session;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      // 読込失敗時に未作成の画面へ進ませず、既存データを保護する。
      setState(() {
        _loadFailed = true;
        _error = '保存済みウォレットを読み込めませんでした。端末のロックを解除して再試行してください。保存データは変更していません。';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openForm(bool create) async {
    if (_busy || _loadFailed) return;
    final replace = _session != null;
    if (replace) {
      final approved = await _confirm(
        '保存済みウォレットを置き換えますか？',
        '現在のウォレットを置き換えます。現在のフレーズとパスフレーズを控えていることを確認してください。',
        '置き換える',
      );
      if (!mounted || !approved) return;
    }
    if (!mounted) return;
    final session = await Navigator.push<BitcoinWalletSession>(
      context,
      MaterialPageRoute(
        builder: (_) => BitcoinWalletFormView(
          service: _service,
          create: create,
          replace: replace,
        ),
      ),
    );
    if (mounted && session != null) {
      setState(() {
        _session = session;
        _error = null;
      });
    }
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _delete() async {
    if (_busy) return;
    final approved = await _confirm(
      'この端末から削除しますか？',
      '再び利用するにはフレーズとパスフレーズが必要です。このウォレットの復元情報とすべての通貨の設定を端末から削除します。ブロックチェーン上の資産は削除されません。',
      '削除する',
    );
    if (!mounted || !approved) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.delete();
      if (mounted) {
        setState(() {
          _session = null;
          _loadFailed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '削除できませんでした。ウォレットは引き続き保存されています。再試行してください。');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyAddress() async {
    final address = _session?.address.address;
    if (address == null) return;
    try {
      await Clipboard.setData(ClipboardData(text: address));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('アドレスをコピーしました')));
    } catch (_) {
      if (mounted) setState(() => _error = 'コピーできませんでした。アドレスを長押ししてコピーしてください。');
    }
  }

  Future<void> _settings() async {
    final session = _session;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => BitcoinSettingsSheet(
        network: session == null ? null : _networkName(session.account.network),
        path: session?.address.path,
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'create':
        await _openForm(true);
      case 'restore':
        await _openForm(false);
      case 'delete':
        await _delete();
    }
  }

  String _networkName(WalletNetwork network) => switch (network) {
    WalletNetwork.bitcoin => 'Bitcoin Mainnet',
    WalletNetwork.testnet => 'Testnet',
    WalletNetwork.signet => 'Signet',
    WalletNetwork.regtest => 'Regtest',
  };

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const WalletPageLayout(
        title: 'HD Wallet',
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 64),
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text('ウォレットを読み込んでいます…'),
            ],
          ),
        ),
      );
    }
    if (_loadFailed) {
      return WalletPageLayout(
        title: 'HD Wallet',
        action: FilledButton(onPressed: _load, child: const Text('読込を再試行')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ウォレットを\n開けませんでした。',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            WalletErrorMessage(_error!),
            const SizedBox(height: 24),
            TextButton(onPressed: _delete, child: const Text('保存データをこの端末から削除')),
          ],
        ),
      );
    }
    final session = _session;
    if (session == null) {
      return BitcoinWelcome(
        onCreate: () => _openForm(true),
        onRestore: () => _openForm(false),
      );
    }
    final network = _networkName(session.account.network);
    return WalletPageLayout(
      title: 'HD Wallet',
      actions: [
        IconButton(
          tooltip: 'ウォレット設定',
          onPressed: _settings,
          icon: const Icon(Icons.tune),
        ),
      ],
      action: FilledButton.icon(
        onPressed: _copyAddress,
        icon: const Icon(Icons.copy_outlined),
        label: const Text('アドレスをコピー'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Bitcoinを受け取る',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text('このアドレスを送信元に伝えてください。'),
          const SizedBox(height: 28),
          BitcoinReceiveCard(
            network: network,
            address: session.address.address,
          ),
          const SizedBox(height: 20),
          Text(
            session.account.network == WalletNetwork.bitcoin
                ? 'Bitcoinメインネットのアドレスです。送信元のネットワークを確認してください。'
                : '$network のテスト用アドレスです。メインネットのBitcoinは送らないでください。',
          ),
          const SizedBox(height: 24),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('ウォレットはこの端末に保存済みです。')),
            ],
          ),
          if (_error != null) WalletErrorMessage(_error!),
        ],
      ),
    );
  }
}
