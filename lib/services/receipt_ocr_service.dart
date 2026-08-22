import 'receipt_ocr_impl.dart';
import 'receipt_ocr_models.dart';

export 'receipt_ocr_models.dart';

class ReceiptOcrService {
  ReceiptOcrService._();
  static final instance = ReceiptOcrService._();

  Future<ReceiptOcrResult> scanFile(String path) => scanReceiptFile(path);
}
