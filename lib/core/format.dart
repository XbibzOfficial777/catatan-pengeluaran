import 'dart:math' as math;

/// Status privasi nominal (mode sembunyikan angka) dipusatkan di satu tempat.
///
/// Sebelumnya berupa variabel global mutable di main.dart yang ditulis dari
/// beberapa lokasi; kini diganti kelas tunggal yang mudah diaudit dan nantinya
/// bisa dinaikkan menjadi ChangeNotifier.
class PrivacyMask {
  PrivacyMask._();

  static bool enabled = false;
}

String formatCurrency(double value) =>
    PrivacyMask.enabled ? '••••••' : 'Rp ${formatNumber(value)}';

String formatNumber(double value) {
  final fixed = value.round().toString();
  return fixed.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
}

double parseAmount(String raw) {
  final normalized = raw
      .trim()
      .replaceAll(' ', '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(9999)}';

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}


