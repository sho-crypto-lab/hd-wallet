import 'package:flutter/material.dart';
import 'package:hd_wallet/src/wallet/bitcoin/models/bitcoin_wallet.dart';
import '../widgets/wallet_page_layout.dart';

/// 新規作成の直後だけフレーズを表示する。通常の受取画面には渡して表示しない。
class BitcoinBackupView extends StatefulWidget {
  const BitcoinBackupView({super.key, required this.session});
  final BitcoinWalletSession session;

  @override
  State<BitcoinBackupView> createState() => _BitcoinBackupViewState();
}

class _BitcoinBackupViewState extends State<BitcoinBackupView> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final words = widget.session.wallet.phrase.split(RegExp(r'\s+'));
    return PopScope(
      canPop: _confirmed,
      child: WalletPageLayout(
        title: 'フレーズのバックアップ',
        automaticallyImplyLeading: false,
        action: FilledButton(
          onPressed: _confirmed ? () => Navigator.pop(context) : null,
          child: const Text('受取画面へ進む'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.key_outlined, size: 36),
            const SizedBox(height: 20),
            Text(
              'この12単語を、\n大切に保管してください。',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'ウォレットは端末に保存されました。端末の紛失や故障に備えて、単語を順番どおりに控えてください。他人には共有しないでください。',
            ),
            if (widget.session.wallet.passphrase.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('復元には、設定したパスフレーズも必要です。フレーズと合わせて控えてください。'),
            ],
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(
                    words.length,
                    (index) => Container(
                      width: width,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${index + 1}'.padLeft(2, '0'),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              words[index],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _confirmed,
              onChanged: (value) => setState(() => _confirmed = value ?? false),
              title: const Text('フレーズを安全な場所に控えました'),
            ),
          ],
        ),
      ),
    );
  }
}
