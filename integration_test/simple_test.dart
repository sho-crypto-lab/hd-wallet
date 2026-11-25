import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hd_wallet/app.dart';
import 'package:hd_wallet/src/wallet/bitcoin/views/bitcoin_wallet_view.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hd_wallet/src/core/storage/secure_storage.dart';
import 'package:hd_wallet/src/core/storage/wallet_storage.dart';
import 'package:hd_wallet/src/wallet/bitcoin/services/bitcoin_wallet_service.dart';
import 'package:hd_wallet/src/wallet/bitcoin/storage/bitcoin_wallet_storage.dart';
import 'package:hd_wallet/src/rust/api/wallet.dart';
import 'package:hd_wallet/src/rust/frb_generated.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());
  const secure = SecureStorage(
    storage: FlutterSecureStorage(
      iOptions: IOSOptions(
        accountName: 'hd_wallet.integration_test',
        accessibility: KeychainAccessibility.unlocked_this_device,
        synchronizable: false,
      ),
    ),
  );
  const shared = WalletStorage(storage: secure);
  BitcoinWalletService service() => BitcoinWalletService(
    storage: const BitcoinWalletStorage(storage: shared),
  );
  setUp(() async => shared.delete());
  tearDown(() async => shared.delete());
  tearDownAll(RustLib.dispose);
  testWidgets('Restores a wallet through the UI and the real Rust API', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(home: BitcoinWalletView(service: service())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('既存のウォレットを復元'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('詳細設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<WalletNetwork>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bitcoin（メインネット）').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
    );
    final restore = find.text('復元して保存する');
    await tester.ensureVisible(restore);
    await tester.tap(restore);
    await tester.pumpAndSettle();
    expect(
      find.text('bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(MyApp(home: BitcoinWalletView(service: service())));
    await tester.pumpAndSettle();
    expect(
      find.text('bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNothing);
  });
}
