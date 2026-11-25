import 'package:flutter/material.dart';

/// ネットワーク名と受取アドレスを表示する。
class BitcoinReceiveCard extends StatelessWidget {
  const BitcoinReceiveCard({
    super.key,
    required this.network,
    required this.address,
  });

  final String network;
  final String address;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE6E2DB)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFFFF0DC),
              foregroundColor: Color(0xFF985100),
              child: Icon(Icons.currency_bitcoin),
            ),
            SizedBox(width: 12),
            Text(
              'Bitcoin',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Chip(label: Text(network), avatar: const Icon(Icons.public, size: 16)),
        const SizedBox(height: 20),
        Text('受取アドレス', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        SelectableText(
          address,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            height: 1.7,
          ),
        ),
      ],
    ),
  );
}
