import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hd_wallet/app.dart';
import 'package:hd_wallet/src/wallet/bitcoin/views/bitcoin_wallet_view.dart';
import 'package:hd_wallet/src/core/storage/wallet_storage.dart';
import 'package:hd_wallet/src/rust/api/wallet.dart';
import 'package:hd_wallet/src/rust/frb_generated.dart';
import 'package:hd_wallet/src/wallet/bitcoin/services/bitcoin_wallet_service.dart';
import 'package:hd_wallet/src/wallet/bitcoin/storage/bitcoin_wallet_storage.dart';
import '../../../support/fake_wallet_api.dart';
import '../../../support/memory_secure_storage.dart';

Future<void> tapButton(WidgetTester tester, String label) async {
  final button = find.text(label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  late FakeWalletApi api;
  late MemorySecureStorage memory;
  BitcoinWalletService service() => BitcoinWalletService(
    storage: BitcoinWalletStorage(storage: WalletStorage(storage: memory)),
  );
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(MyApp(home: BitcoinWalletView(service: service())));
    await tester.pumpAndSettle();
  }

  Future<void> seedWallet() async {
    await service().restore(
      phrase: testPhrase,
      passphrase: 'secret',
      network: WalletNetwork.signet,
      account: 2,
      index: 3,
    );
  }

  setUp(() {
    api = FakeWalletApi();
    memory = MemorySecureStorage();
    RustLib.initMock(api: api);
  });
  tearDown(RustLib.dispose);

  testWidgets('First launch offers separate creation and restore actions', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('ウォレットを作成'), findsOneWidget);
    expect(find.text('既存のウォレットを復元'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tapButton(tester, '既存のウォレットを復元');
    expect(find.widgetWithText(TextFormField, 'リカバリーフレーズ'), findsOneWidget);
    expect(find.text('詳細設定'), findsOneWidget);
  });

  testWidgets(
    'Restores and saves all settings then hides recovery information',
    (tester) async {
      await pumpApp(tester);
      await tapButton(tester, '既存のウォレットを復元');
      await tester.enterText(find.byType(TextFormField).first, testPhrase);
      await tapButton(tester, '詳細設定');
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(1), 'secret');
      await tester.enterText(fields.at(2), '2');
      await tester.enterText(fields.at(3), '3');
      await tapButton(tester, '復元して保存する');
      expect(find.text('tb1q-test-address'), findsOneWidget);
      expect(find.text('アドレスをコピー'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text(testPhrase), findsNothing);
      expect(api.receivedPassphrase, 'secret');
      expect(api.receivedAccount, 2);
      expect(api.receivedIndex, 3);
      expect(memory.values, hasLength(1));
    },
  );

  testWidgets('Creation shows numbered backup words before receive screen', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapButton(tester, 'ウォレットを作成');
    expect(find.byType(TextFormField), findsNothing);
    await tapButton(tester, 'ウォレットを作成する');
    expect(memory.values, hasLength(1));
    expect(find.text('01'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('abandon'), findsNWidgets(11));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '受取画面へ進む'))
          .onPressed,
      isNull,
    );
    await tapButton(tester, 'フレーズを安全な場所に控えました');
    await tapButton(tester, '受取画面へ進む');
    expect(find.text('tb1q-test-address'), findsOneWidget);
    expect(find.text('abandon'), findsNothing);
  });

  testWidgets('An invalid phrase stays on the input screen without saving', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapButton(tester, '既存のウォレットを復元');
    await tester.enterText(find.byType(TextFormField).first, 'invalid');
    await tapButton(tester, '復元して保存する');
    expect(find.textContaining('フレーズを確認してください。'), findsOneWidget);
    expect(memory.values, isEmpty);
  });

  testWidgets('A failed save stays on the form and can be retried', (
    tester,
  ) async {
    memory.failWrite = true;
    await pumpApp(tester);
    await tapButton(tester, '既存のウォレットを復元');
    await tester.enterText(find.byType(TextFormField).first, testPhrase);
    await tapButton(tester, '復元して保存する');
    expect(find.textContaining('保存に失敗しました。'), findsOneWidget);
    expect(find.text('Bitcoinを受け取る'), findsNothing);
    memory.failWrite = false;
    await tapButton(tester, '復元して保存する');
    expect(find.text('tb1q-test-address'), findsOneWidget);
  });

  testWidgets(
    'A new app instance restores the address without exposing the phrase',
    (tester) async {
      await seedWallet();
      await pumpApp(tester);
      expect(find.text('tb1q-test-address'), findsOneWidget);
      expect(find.text('Signet'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text(testPhrase), findsNothing);
      expect(find.text('secret'), findsNothing);
    },
  );

  testWidgets('Copy action places the full address on the clipboard', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await seedWallet();
    await pumpApp(tester);
    await tapButton(tester, 'アドレスをコピー');
    expect(
      calls
          .where((call) => call.method == 'Clipboard.setData')
          .single
          .arguments,
      {'text': 'tb1q-test-address'},
    );
    expect(find.text('アドレスをコピーしました'), findsOneWidget);
  });

  testWidgets('Replacement cancellation leaves the saved wallet unchanged', (
    tester,
  ) async {
    await seedWallet();
    final original = Map<String, String>.from(memory.values);
    await pumpApp(tester);
    await tester.tap(find.byTooltip('ウォレット設定'));
    await tester.pumpAndSettle();
    await tapButton(tester, '新しいウォレットに置き換える');
    await tapButton(tester, 'キャンセル');
    expect(memory.values, original);
    expect(api.generations, 0);
    expect(find.text('tb1q-test-address'), findsOneWidget);
  });

  testWidgets(
    'Delete failures preserve the screen and a retry clears the wallet',
    (tester) async {
      await seedWallet();
      await pumpApp(tester);
      memory.failDelete = true;
      Future<void> remove() async {
        await tester.tap(find.byTooltip('ウォレット設定'));
        await tester.pumpAndSettle();
        await tapButton(tester, 'この端末からウォレットを削除');
        await tapButton(tester, '削除する');
      }

      await remove();
      expect(find.textContaining('削除できませんでした。'), findsOneWidget);
      expect(memory.values, isNotEmpty);
      memory.failDelete = false;
      await remove();
      expect(memory.values, isEmpty);
      expect(find.text('既存のウォレットを復元'), findsOneWidget);
    },
  );

  testWidgets(
    'A read failure does not expose creation actions or overwrite data',
    (tester) async {
      await seedWallet();
      final original = Map<String, String>.from(memory.values);
      memory.failRead = true;
      await pumpApp(tester);
      expect(find.text('読込を再試行'), findsOneWidget);
      expect(find.text('ウォレットを作成'), findsNothing);
      expect(memory.values, original);
      memory.failRead = false;
      await tapButton(tester, '読込を再試行');
      expect(find.text('tb1q-test-address'), findsOneWidget);
    },
  );

  testWidgets('Small screen and large text keep the main actions reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
        child: MyApp(home: BitcoinWalletView(service: service())),
      ),
    );
    await tester.pumpAndSettle();
    await tapButton(tester, '既存のウォレットを復元');
    expect(tester.takeException(), isNull);
    await tapButton(tester, '復元して保存する');
    expect(find.text('リカバリーフレーズを入力してください'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
