import 'package:flutter/material.dart';
import '../models/home_data.dart';
import 'home_format.dart';

class RecentTransactions extends StatelessWidget {
  const RecentTransactions({
    super.key,
    required this.transactions,
    required this.hidden,
    this.onHistory,
    this.unavailableText = '取引履歴は未取得です',
  });
  final HomeSection<List<HomeTransaction>> transactions;
  final bool hidden;
  final VoidCallback? onHistory;
  final String unavailableText;

  @override
  Widget build(BuildContext context) {
    final items = transactions.data ?? const <HomeTransaction>[];
    final message = switch (transactions.state) {
      HomeLoadState.loading => '取引履歴を取得しています…',
      HomeLoadState.error => '取引履歴を取得できませんでした',
      HomeLoadState.unavailable => unavailableText,
      HomeLoadState.loaded => items.isEmpty ? 'まだ取引がありません' : null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '最近の取引',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (onHistory != null) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: '取引履歴をすべて見る',
                child: TextButton(
                  onPressed: onHistory,
                  child: const Text('すべて見る'),
                ),
              ),
            ],
          ],
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: transactions.state == HomeLoadState.error
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
                if (transactions.state == HomeLoadState.loaded) ...[
                  const SizedBox(height: 8),
                  Text(
                    '送金や受取を行うと、ここに表示されます。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        if (transactions.state == HomeLoadState.loaded)
          for (final item in items.take(3))
            _TransactionRow(transaction: item, hidden: hidden),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, required this.hidden});
  final HomeTransaction transaction;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final sent = transaction.direction == HomeTransactionDirection.sent;
    final status = switch (transaction.status) {
      HomeTransactionStatus.pending => '承認待ち',
      HomeTransactionStatus.confirmed => '承認済み',
      HomeTransactionStatus.failed => '失敗',
    };
    final quantity = hidden
        ? '••••'
        : '${sent ? '−' : '+'}${transaction.quantity} ${transaction.symbol}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3;
          final amounts = Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                quantity,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: transaction.status == HomeTransactionStatus.failed
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
              ),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ExcludeSemantics(
                    child: SizedBox(
                      width: 40,
                      child: Icon(
                        sent ? Icons.arrow_outward : Icons.south_west,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sent ? '送金' : '受取',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatHomeDate(transaction.date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (!stacked) ...[
                    const SizedBox(width: 12),
                    Flexible(child: amounts),
                  ],
                ],
              ),
              if (stacked)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: amounts,
                ),
            ],
          );
        },
      ),
    );
  }
}
