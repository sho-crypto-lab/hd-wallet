import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.walletName,
    this.onSwitchWallet,
    this.onScan,
  });
  final String walletName;
  final VoidCallback? onSwitchWallet;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Semantics(
          button: true,
          enabled: onSwitchWallet != null,
          label: onSwitchWallet == null
              ? '$walletName、ウォレット切り替えは準備中'
              : '$walletName、ウォレットを切り替える',
          excludeSemantics: true,
          child: InkWell(
            onTap: onSwitchWallet,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      walletName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: onSwitchWallet == null
                        ? Theme.of(context).disabledColor
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 16),
      IconButton(
        onPressed: onScan,
        tooltip: onScan == null ? 'QRコードスキャン（準備中）' : 'QRコードをスキャン',
        icon: const Icon(Icons.qr_code_scanner_outlined),
      ),
    ],
  );
}
