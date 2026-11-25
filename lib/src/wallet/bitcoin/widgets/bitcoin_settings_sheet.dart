import 'package:flutter/material.dart';

/// 設定の表示と操作選択。選択結果を呼び出し元へ返す。
class BitcoinSettingsSheet extends StatelessWidget {
  const BitcoinSettingsSheet({super.key, this.network, this.path});

  final String? network;
  final String? path;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ウォレット設定', style: Theme.of(context).textTheme.titleLarge),
          if (network != null && path != null) ...[
            const SizedBox(height: 20),
            Text('ネットワーク：$network'),
            const SizedBox(height: 8),
            const Text('派生パス · BIP-84 / Native SegWit'),
            SelectableText(path!),
          ],
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('新しいウォレットに置き換える'),
            onTap: () => Navigator.pop(context, 'create'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.restore),
            title: const Text('別のウォレットを復元する'),
            onTap: () => Navigator.pop(context, 'restore'),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            textColor: Theme.of(context).colorScheme.error,
            iconColor: Theme.of(context).colorScheme.error,
            leading: const Icon(Icons.delete_outline),
            title: const Text('この端末からウォレットを削除'),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    ),
  );
}
