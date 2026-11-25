import 'package:flutter/material.dart';
import '../models/home_data.dart';
import 'home_format.dart';

class AssetList extends StatelessWidget {
  const AssetList({
    super.key,
    required this.assets,
    required this.hidden,
    this.onTap,
  });
  final HomeSection<List<HomeAsset>> assets;
  final bool hidden;
  final ValueChanged<HomeAsset>? onTap;

  @override
  Widget build(BuildContext context) {
    final values = assets.data ?? const <HomeAsset>[];
    final message = switch (assets.state) {
      HomeLoadState.loading => '保有資産を取得しています…',
      HomeLoadState.error => '保有資産を取得できませんでした',
      HomeLoadState.unavailable => '保有数量・評価額は未取得です',
      HomeLoadState.loaded => values.isEmpty ? '保有資産はありません' : null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('保有資産', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: assets.state == HomeLoadState.error
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
          ),
        for (final asset in values)
          InkWell(
            onTap: onTap == null ? null : () => onTap!(asset),
            borderRadius: BorderRadius.circular(12),
            child: _AssetRow(
              asset: asset,
              hidden: hidden,
              available: assets.state == HomeLoadState.loaded,
            ),
          ),
      ],
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.asset,
    required this.hidden,
    required this.available,
  });
  final HomeAsset asset;
  final bool hidden;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final quantity = hidden
        ? '••••'
        : available
        ? asset.quantity ?? '—'
        : '—';
    final jpy = hidden
        ? '••••'
        : available && asset.jpyValue != null
        ? formatHomeYen(asset.jpyValue!)
        : '—';
    final name = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(asset.name, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(asset.symbol, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
    final amounts = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$quantity ${asset.symbol}',
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          jpy,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      child: Icon(asset.icon),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: name),
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
