/// 表示上の整形のみを行い、通貨換算や残高計算はしない。
String formatHomeYen(int value) {
  final digits = value.abs().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '${value < 0 ? '-' : ''}¥$digits';
}

String formatHomeDate(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}/${two(local.month)}/${two(local.day)}  ${two(local.hour)}:${two(local.minute)}';
}
