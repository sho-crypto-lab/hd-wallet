import 'package:flutter/material.dart';
import '../models/home_data.dart';
import 'home_format.dart';

class TotalBalance extends StatelessWidget {
  const TotalBalance({
    super.key,
    required this.balance,
    required this.hidden,
    required this.onToggle,
    this.onRetry,
  });
  final HomeSection<int> balance;
  final bool hidden;
  final VoidCallback onToggle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final String status = switch (balance.state) {
      HomeLoadState.unavailable => '残高は未取得です',
      HomeLoadState.loading => '残高を取得しています',
      HomeLoadState.error => '残高を取得できませんでした',
      HomeLoadState.loaded => balance.data == null ? '残高は未取得です' : '日本円換算',
    };
    final value = hidden
        ? '••••••'
        : balance.state == HomeLoadState.loaded && balance.data != null
        ? formatHomeYen(balance.data!)
        : '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('総資産', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(width: 4),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: hidden ? '残高を表示' : '残高を非表示',
              onPressed: onToggle,
              icon: Icon(
                hidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // スクリーンリーダーにも非表示前の数値を残さない。
        Semantics(
          label: hidden ? '総資産は非表示です' : '総資産 $value',
          excludeSemantics: true,
          child: Text(value, style: Theme.of(context).textTheme.displaySmall),
        ),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (balance.state == HomeLoadState.loading) ...[
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: balance.state == HomeLoadState.error
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
              ),
              if (balance.state == HomeLoadState.error && onRetry != null)
                TextButton(onPressed: onRetry, child: const Text('再試行')),
            ],
          ),
        ),
      ],
    );
  }
}
