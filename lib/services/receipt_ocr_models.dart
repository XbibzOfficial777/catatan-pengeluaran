class ReceiptOcrResult {
  const ReceiptOcrResult({
    required this.text,
    this.merchant,
    this.amount,
    this.date,
  });

  final String text;
  final String? merchant;
  final double? amount;
  final DateTime? date;
}

class ReceiptOcrUnsupportedException implements Exception {
  const ReceiptOcrUnsupportedException();

  @override
  String toString() => 'OCR struk tersedia pada Android dan iOS, bukan Web.';
}
