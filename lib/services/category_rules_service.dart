import '../models/advanced_finance_models.dart';
import '../models/finance_models.dart';

class CategoryRulesService {
  static ExpenseCategory suggest({
    required String title,
    String merchant = '',
    List<MerchantCategoryRule> rules = const <MerchantCategoryRule>[],
  }) {
    final haystack = '$merchant $title'.trim().toLowerCase();
    for (final rule in rules.where(
      (item) => item.enabled && item.pattern.trim().isNotEmpty,
    )) {
      if (haystack.contains(rule.pattern.trim().toLowerCase())) {
        return rule.category;
      }
    }
    const defaults = <ExpenseCategory, List<String>>{
      ExpenseCategory.food: [
        'makan',
        'resto',
        'restaurant',
        'warung',
        'kopi',
        'coffee',
        'gofood',
        'grabfood',
        'minum',
      ],
      ExpenseCategory.transport: [
        'gojek',
        'grab',
        'bensin',
        'pertalite',
        'parkir',
        'tol',
        'bus',
        'kereta',
        'taksi',
      ],
      ExpenseCategory.shopping: [
        'belanja',
        'tokopedia',
        'shopee',
        'lazada',
        'mall',
        'minimarket',
        'indomaret',
        'alfamart',
      ],
      ExpenseCategory.bills: [
        'listrik',
        'pln',
        'internet',
        'wifi',
        'pulsa',
        'tagihan',
        'air',
        'pdam',
      ],
      ExpenseCategory.health: [
        'dokter',
        'klinik',
        'rumah sakit',
        'obat',
        'apotek',
        'medical',
      ],
      ExpenseCategory.entertainment: [
        'bioskop',
        'netflix',
        'spotify',
        'game',
        'rekreasi',
        'hiburan',
      ],
    };
    for (final entry in defaults.entries) {
      if (entry.value.any(haystack.contains)) return entry.key;
    }
    return ExpenseCategory.other;
  }
}
