import 'package:flutter/material.dart';
import 'package:hd_wallet/src/core/wallet/mnemonic.dart';
import 'package:hd_wallet/src/rust/api/wallet.dart';
import 'package:hd_wallet/src/wallet/bitcoin/models/bitcoin_wallet.dart';
import 'package:hd_wallet/src/wallet/bitcoin/services/bitcoin_wallet_service.dart';
import 'bitcoin_backup_view.dart';
import '../widgets/wallet_error_message.dart';
import '../widgets/wallet_page_layout.dart';

/// 作成と復元の入力を分け、通常操作に不要な派生設定は詳細設定へまとめる。
class BitcoinWalletFormView extends StatefulWidget {
  const BitcoinWalletFormView({
    super.key,
    required this.service,
    required this.create,
    this.replace = false,
  });
  final BitcoinWalletService service;
  final bool create;
  final bool replace;

  @override
  State<BitcoinWalletFormView> createState() => _BitcoinWalletFormViewState();
}

class _BitcoinWalletFormViewState extends State<BitcoinWalletFormView> {
  final _form = GlobalKey<FormState>();
  final _phrase = TextEditingController();
  final _passphrase = TextEditingController();
  final _account = TextEditingController(text: '0');
  final _index = TextEditingController(text: '0');
  WalletNetwork _network = WalletNetwork.testnet;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phrase.dispose();
    _passphrase.dispose();
    _account.dispose();
    _index.dispose();
    super.dispose();
  }

  String? _validateIndex(String? value) {
    final index = int.tryParse(value ?? '');
    return index == null || index < 0 || index >= 0x80000000
        ? '0〜2147483647の整数を入力してください'
        : null;
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_validateIndex(_account.text) != null ||
        _validateIndex(_index.text) != null) {
      setState(
        () => _error = '詳細設定のアカウント番号とアドレスインデックスには、0〜2147483647の整数を入力してください。',
      );
      return;
    }
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final BitcoinWalletSession session;
      if (widget.create) {
        session = await widget.service.create(
          passphrase: _passphrase.text,
          network: _network,
          account: int.parse(_account.text),
          index: int.parse(_index.text),
          replace: widget.replace,
        );
      } else {
        session = await widget.service.restore(
          phrase: _phrase.text,
          passphrase: _passphrase.text,
          network: _network,
          account: int.parse(_account.text),
          index: int.parse(_index.text),
          replace: widget.replace,
        );
      }
      if (!mounted) return;
      // 保存完了後にだけ成功画面へ進む。作成時はバックアップ確認を挟む。
      _phrase.clear();
      _passphrase.clear();
      if (widget.create) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => BitcoinBackupView(session: session),
          ),
        );
      }
      if (mounted) Navigator.pop(context, session);
    } on InvalidMnemonic {
      if (mounted) {
        setState(() => _error = 'フレーズを確認してください。単語・順番・単語数のいずれかが正しくありません。');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'ウォレットの作成・復元または保存に失敗しました。入力内容を確認して再試行してください。');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: WalletPageLayout(
        title: widget.create ? 'ウォレットを作成' : 'ウォレットを復元',
        leading: BackButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
        ),
        action: FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('安全に保存しています…'),
                  ],
                )
              : Text(widget.create ? 'ウォレットを作成する' : '復元して保存する'),
        ),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.create ? 'あなたのBitcoinを、\nあなたの手元に。' : 'おかえりなさい。',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                widget.create
                    ? '12単語のリカバリーフレーズを作成し、ウォレットをこの端末に保存します。次の画面でフレーズを控えてください。'
                    : 'バックアップしたリカバリーフレーズを、元の順番で入力してください。',
              ),
              const SizedBox(height: 28),
              if (!widget.create) ...[
                TextFormField(
                  controller: _phrase,
                  enabled: !_busy,
                  minLines: 4,
                  maxLines: 7,
                  autocorrect: false,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  decoration: const InputDecoration(
                    labelText: 'リカバリーフレーズ',
                    hintText: '単語をスペースで区切って入力',
                    helperText: '英語の12・15・18・21・24単語に対応',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'リカバリーフレーズを入力してください'
                      : null,
                ),
                const SizedBox(height: 24),
              ],
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExpansionTile(
                  title: const Text('詳細設定'),
                  subtitle: Text('${_network.name} · アカウント ${_account.text}'),
                  maintainState: true,
                  childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    DropdownButtonFormField<WalletNetwork>(
                      initialValue: _network,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'ネットワーク'),
                      items: const [
                        DropdownMenuItem(
                          value: WalletNetwork.bitcoin,
                          child: Text('Bitcoin（メインネット）'),
                        ),
                        DropdownMenuItem(
                          value: WalletNetwork.testnet,
                          child: Text('Testnet'),
                        ),
                        DropdownMenuItem(
                          value: WalletNetwork.signet,
                          child: Text('Signet'),
                        ),
                        DropdownMenuItem(
                          value: WalletNetwork.regtest,
                          child: Text('Regtest'),
                        ),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _network = value);
                              }
                            },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passphrase,
                      enabled: !_busy,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      enableIMEPersonalizedLearning: false,
                      decoration: const InputDecoration(
                        labelText: 'BIP-39パスフレーズ（任意）',
                        helperText: 'アプリのパスワードとは異なります。復元時は元と同じ値が必要です。',
                        helperMaxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _account,
                      enabled: !_busy,
                      keyboardType: TextInputType.number,
                      validator: _validateIndex,
                      decoration: const InputDecoration(labelText: 'アカウント番号'),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _index,
                      enabled: !_busy,
                      keyboardType: TextInputType.number,
                      validator: _validateIndex,
                      decoration: const InputDecoration(
                        labelText: 'アドレスインデックス',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('この端末に暗号化して保存します。フレーズをサーバーへ送信することはありません。'),
                  ),
                ],
              ),
              if (_error != null) WalletErrorMessage(_error!),
            ],
          ),
        ),
      ),
    );
  }
}
