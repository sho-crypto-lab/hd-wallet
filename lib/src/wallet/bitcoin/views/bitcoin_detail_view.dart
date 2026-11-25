import 'package:flutter/material.dart';
import 'package:hd_wallet/src/ui/home/models/home_data.dart';
import 'package:hd_wallet/src/ui/home/widgets/home_format.dart';
import 'package:hd_wallet/src/ui/home/widgets/recent_transactions.dart';
import 'package:hd_wallet/src/wallet/bitcoin/services/bitcoin_wallet_service.dart';

import 'bitcoin_wallet_view.dart';

/// Bitcoinの資産詳細。鍵や復元情報は受取画面側で扱う。
class BitcoinDetailView extends StatefulWidget {
  const BitcoinDetailView({
    super.key,
    this.quantity,
    this.jpyValue,
    this.transactions = const HomeSection.unavailable(),
    this.initiallyHidden = false,
    this.service,
    this.onSend,
  });

  final String? quantity;
  final int? jpyValue;
  final HomeSection<List<HomeTransaction>> transactions;
  final bool initiallyHidden;
  final BitcoinWalletService? service;
  final VoidCallback? onSend;

  @override
  State<BitcoinDetailView> createState() => _BitcoinDetailViewState();
}

class _BitcoinDetailViewState extends State<BitcoinDetailView> {
  late bool _hidden;

  @override
  void initState() {
    super.initState();
    _hidden = widget.initiallyHidden;
  }

  void _receive() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BitcoinWalletView(service: widget.service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quantity = _hidden ? '••••••' : widget.quantity ?? '—';
    final fiat = _hidden
        ? '••••••'
        : widget.jpyValue == null
        ? '—'
        : formatHomeYen(widget.jpyValue!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bitcoin'),
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const ExcludeSemantics(
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Color(0xFFF7931A),
                          foregroundColor: Colors.white,
                          child: Icon(Icons.currency_bitcoin, size: 34),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bitcoin', style: theme.textTheme.titleLarge),
                            const SizedBox(height: 2),
                            Text('BTC', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Row(
                    children: [
                      Text('保有数量', style: theme.textTheme.labelLarge),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: _hidden ? '残高を表示' : '残高を非表示',
                        onPressed: () => setState(() => _hidden = !_hidden),
                        icon: Icon(
                          _hidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Semantics(
                    label: _hidden ? '保有数量は非表示です' : '保有数量 $quantity BTC',
                    excludeSemantics: true,
                    child: Wrap(
                      spacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(quantity, style: theme.textTheme.displaySmall),
                        Text('BTC', style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label: _hidden ? '日本円換算額は非表示です' : '日本円換算 $fiat',
                    excludeSemantics: true,
                    child: Text(fiat, style: theme.textTheme.titleMedium),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (widget.onSend != null)
                        OutlinedButton.icon(
                          onPressed: widget.onSend,
                          icon: const Icon(Icons.arrow_outward),
                          label: const Text('送金'),
                        ),
                      FilledButton.icon(
                        onPressed: _receive,
                        icon: const Icon(Icons.south_west),
                        label: const Text('受取'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(144, 56),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  const Divider(),
                  const SizedBox(height: 28),
                  RecentTransactions(
                    transactions: widget.transactions,
                    hidden: _hidden,
                    unavailableText: '—',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
