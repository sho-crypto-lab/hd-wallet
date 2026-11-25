import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hd_wallet/app.dart';
import 'package:hd_wallet/src/core/storage/wallet_storage.dart';
import 'package:hd_wallet/src/rust/api/wallet.dart';
import 'package:hd_wallet/src/rust/frb_generated.dart';
import 'package:hd_wallet/src/ui/home/home_theme.dart';
import 'package:hd_wallet/src/ui/home/models/home_data.dart';
import 'package:hd_wallet/src/wallet/bitcoin/services/bitcoin_wallet_service.dart';
import 'package:hd_wallet/src/wallet/bitcoin/storage/bitcoin_wallet_storage.dart';
import 'package:hd_wallet/src/wallet/bitcoin/views/bitcoin_detail_view.dart';

import '../../../support/fake_wallet_api.dart';
import '../../../support/memory_secure_storage.dart';

Future<void> pumpDetail(WidgetTester tester, BitcoinDetailView view) async {
  await tester.pumpWidget(
    MyApp(
      home: Theme(data: buildHomeTheme(), child: view),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Home opens Bitcoin and preserves balance privacy on navigation',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('残高を非表示'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Bitcoin'));
      await tester.tap(find.text('Bitcoin'));
      await tester.pumpAndSettle();

      expect(find.byType(BitcoinDetailView), findsOneWidget);
      expect(find.byTooltip('残高を表示'), findsOneWidget);
      expect(find.textContaining('準備中'), findsNothing);
      expect(find.textContaining('未取得'), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(BitcoinDetailView), findsNothing);
      expect(find.text('保有資産'), findsOneWidget);
      expect(find.byTooltip('残高を表示'), findsOneWidget);
    },
  );

  testWidgets('Absent balances do not appear as zero or fabricated activity', (
    tester,
  ) async {
    await pumpDetail(tester, const BitcoinDetailView());

    expect(find.text('—'), findsNWidgets(3));
    expect(find.text('¥0'), findsNothing);
    expect(find.text('0 BTC'), findsNothing);
    expect(find.text('まだ取引がありません'), findsNothing);
    expect(find.text('準備中'), findsNothing);
    expect(find.text('すべて見る'), findsNothing);
    expect(find.text('送金'), findsNothing);
    expect(find.text('受取'), findsOneWidget);
  });

  testWidgets('Privacy hides both balances and transaction amounts', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpDetail(
        tester,
        BitcoinDetailView(
          quantity: '0.12345678',
          jpyValue: 123456,
          transactions: HomeSection.loaded([
            HomeTransaction(
              id: 'received',
              direction: HomeTransactionDirection.received,
              date: DateTime(2026, 11, 26),
              quantity: '0.02345678',
              symbol: 'BTC',
              status: HomeTransactionStatus.confirmed,
            ),
          ]),
        ),
      );
      expect(find.text('0.12345678'), findsOneWidget);
      expect(find.text('¥123,456'), findsOneWidget);
      expect(find.text('+0.02345678 BTC'), findsOneWidget);

      await tester.tap(find.byTooltip('残高を非表示'));
      await tester.pumpAndSettle();
      expect(find.text('0.12345678'), findsNothing);
      expect(find.text('¥123,456'), findsNothing);
      expect(find.text('+0.02345678 BTC'), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp('0\\.12345678|123,456|0\\.02345678')),
        findsNothing,
      );

      await tester.tap(find.byTooltip('残高を表示'));
      await tester.pumpAndSettle();
      expect(find.text('0.12345678'), findsOneWidget);
      expect(find.text('+0.02345678 BTC'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Receive opens the saved wallet without changing its data', (
    tester,
  ) async {
    RustLib.initMock(api: FakeWalletApi());
    addTearDown(RustLib.dispose);
    final memory = MemorySecureStorage();
    final service = BitcoinWalletService(
      storage: BitcoinWalletStorage(storage: WalletStorage(storage: memory)),
    );
    await service.restore(
      phrase: testPhrase,
      passphrase: 'secret',
      network: WalletNetwork.signet,
      account: 0,
      index: 0,
    );
    final original = Map<String, String>.from(memory.values);
    await pumpDetail(tester, BitcoinDetailView(service: service));
    await tester.tap(find.text('受取'));
    await tester.pumpAndSettle();

    expect(find.text('Bitcoinを受け取る'), findsOneWidget);
    expect(find.text('tb1q-test-address'), findsOneWidget);
    expect(find.text('Signet'), findsOneWidget);
    expect(find.text(testPhrase), findsNothing);
    expect(memory.values, original);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(BitcoinDetailView), findsOneWidget);
  });

  testWidgets('Small screens with large text keep actions reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    var sent = false;
    await pumpDetail(
      tester,
      BitcoinDetailView(
        quantity: '12345678.12345678',
        jpyValue: 1234567890123,
        onSend: () => sent = true,
      ),
    );

    expect(tester.takeException(), isNull);
    final send = find.text('送金');
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(sent, isTrue);
    await tester.ensureVisible(find.text('受取'));
    expect(tester.takeException(), isNull);
  });
}
