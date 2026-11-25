import 'package:flutter/material.dart';

class WalletActions extends StatelessWidget {
  const WalletActions({super.key, this.onSend, this.onReceive});
  final VoidCallback? onSend;
  final VoidCallback? onReceive;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _action(context, '送金', Icons.arrow_outward, onSend)),
      const SizedBox(width: 12),
      Expanded(child: _action(context, '受取', Icons.south_west, onReceive)),
    ],
  );

  Widget _action(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback? callback,
  ) => Tooltip(
    message: callback == null ? '$label（準備中）' : label,
    child: FilledButton(
      onPressed: callback,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    ),
  );
}
