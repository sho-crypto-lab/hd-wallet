import 'package:flutter/material.dart';

/// 各画面で余白・読める幅・スクロール・下部アクションの配置を揃える。
class WalletPageLayout extends StatelessWidget {
  const WalletPageLayout({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final Widget child;
  final Widget? action;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        actions: actions,
      ),
      // body内の下部に操作を置き、キーボード表示時も押せる位置へ追従させる。
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: SizedBox(width: double.infinity, child: child),
                  ),
                ),
              ),
            ),
            if (action != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 512),
                    child: SizedBox(width: double.infinity, child: action),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
