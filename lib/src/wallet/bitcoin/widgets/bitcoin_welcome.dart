import 'package:flutter/material.dart';
import 'wallet_page_layout.dart';

/// 初回表示と作成・復元の入口。操作は親画面へ通知する。
class BitcoinWelcome extends StatelessWidget {
  const BitcoinWelcome({
    super.key,
    required this.onCreate,
    required this.onRestore,
  });

  final VoidCallback onCreate;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) => WalletPageLayout(
    title: 'HD Wallet',
    action: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(onPressed: onCreate, child: const Text('ウォレットを作成')),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRestore, child: const Text('既存のウォレットを復元')),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0DC),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.currency_bitcoin,
            size: 48,
            color: Color(0xFF985100),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'あなたのBitcoin。\nあなたのウォレット。',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 20),
        const Text('新しく始める方はウォレットを作成。\nフレーズをお持ちの方は、ここから復元できます。'),
        const SizedBox(height: 32),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.phone_iphone_outlined),
          title: Text('この端末に保存'),
          subtitle: Text('復元情報を端末内で保護します。'),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.key_outlined),
          title: Text('フレーズはあなたが保管'),
          subtitle: Text('端末を失ったときの復元に必要です。'),
        ),
      ],
    ),
  );
}
