import 'json_helpers.dart';

enum ExpenseCategory {
  food,
  transport,
  shopping,
  bills,
  health,
  entertainment,
  other,
}

enum DebtKind { payable, receivable }

/// Label tampilan tunggal untuk kategori pengeluaran.
///
/// Dipusatkan di model agar UI, export Excel, dan PDF konsisten
/// (sebelumnya ada dua definisi berbeda: 'Makan' vs 'Makanan').
extension ExpenseCategoryLabel on ExpenseCategory {
  String get label => switch (this) {
    ExpenseCategory.food => 'Makanan',
    ExpenseCategory.transport => 'Transportasi',
    ExpenseCategory.shopping => 'Belanja',
    ExpenseCategory.bills => 'Tagihan',
    ExpenseCategory.health => 'Kesehatan',
    ExpenseCategory.entertainment => 'Hiburan',
    ExpenseCategory.other => 'Lainnya',
  };
}

String categoryLabel(ExpenseCategory category) => category.label;

/// ID fallback yang stabil (deterministik dari isi entry) untuk data lama
/// atau hasil restore yang kehilangan field `id`. Stabilitas penting supaya
/// entry yang sama tidak diduplikasi saat merge restore dijalankan ulang.
String _stableFallbackId(Map<String, dynamic> json, {required String prefix}) {
  final declared = json['id'];
  if (declared is String && declared.isNotEmpty) return declared;
  // Toleran terhadap id lama yang tersimpan sebagai angka (lihat json_helpers).
  if (declared is num) return declared.toString();
  final signature = [
    prefix,
    json['title'] ?? json['person'] ?? '',
    json['date'] ?? '',
    json['amount'] ?? '',
    json['note'] ?? '',
  ].join('|');
  var digest = 0;
  for (final unit in signature.codeUnits) {
    digest = ((digest * 31) + unit) & 0x7fffffff;
  }
  return '${prefix}_recovered_$digest';
}

class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
    this.imagePath,
    this.accountId,
    this.recurringId,
    this.merchantName = '',
    this.receiptText = '',
    this.isBusiness = false,
    this.taxDeductible = false,
    this.taxAmount = 0,
    this.splitBillId,
    this.isSettled = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String note;
  final String? imagePath;
  final String? accountId;
  final String? recurringId;
  final String merchantName;
  final String receiptText;
  final bool isBusiness;
  final bool taxDeductible;
  final double taxAmount;
  final String? splitBillId;
  final bool isSettled;
  final DateTime createdAt;

  ExpenseEntry copyWith({
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
    String? imagePath,
    bool clearImage = false,
    String? accountId,
    bool clearAccount = false,
    String? recurringId,
    String? merchantName,
    String? receiptText,
    bool? isBusiness,
    bool? taxDeductible,
    double? taxAmount,
    String? splitBillId,
    bool? isSettled,
  }) {
    return ExpenseEntry(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      accountId: clearAccount ? null : accountId ?? this.accountId,
      recurringId: recurringId ?? this.recurringId,
      merchantName: merchantName ?? this.merchantName,
      receiptText: receiptText ?? this.receiptText,
      isBusiness: isBusiness ?? this.isBusiness,
      taxDeductible: taxDeductible ?? this.taxDeductible,
      taxAmount: taxAmount ?? this.taxAmount,
      splitBillId: splitBillId ?? this.splitBillId,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category.name,
    'date': date.toIso8601String(),
    'note': note,
    'imagePath': imagePath,
    'accountId': accountId,
    'recurringId': recurringId,
    'merchantName': merchantName,
    'receiptText': receiptText,
    'isBusiness': isBusiness,
    'taxDeductible': taxDeductible,
    'taxAmount': taxAmount,
    'splitBillId': splitBillId,
    'isSettled': isSettled,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) {
    final categoryName = readString(
      json['category'],
      fallback: ExpenseCategory.other.name,
    );
    return ExpenseEntry(
      id: _stableFallbackId(json, prefix: 'expense'),
      title: readString(json['title'], fallback: 'Pengeluaran'),
      amount: roundMoney(readDouble(json['amount'])),
      category: readEnum(
        ExpenseCategory.values,
        categoryName,
        ExpenseCategory.other,
      ),
      date: readDate(json['date']),
      note: readString(json['note']),
      imagePath: readNullableString(json['imagePath']),
      accountId: readNullableString(json['accountId']),
      recurringId: readNullableString(json['recurringId']),
      merchantName: readString(json['merchantName']),
      receiptText: readString(json['receiptText']),
      isBusiness: readBool(json['isBusiness']),
      taxDeductible: readBool(json['taxDeductible']),
      taxAmount: roundMoney(readDouble(json['taxAmount'])),
      splitBillId: readNullableString(json['splitBillId']),
      isSettled: json.containsKey('isSettled')
          ? readBool(json['isSettled'])
          : true,
      createdAt: readDate(json['createdAt']),
    );
  }
}

class DebtEntry {
  const DebtEntry({
    required this.id,
    required this.person,
    required this.amount,
    required this.kind,
    required this.date,
    this.dueDate,
    this.note = '',
    this.imagePath,
    this.contactId,
    this.contactPhone,
    this.isSettled = false,
    required this.createdAt,
  });

  final String id;
  final String person;
  final double amount;
  final DebtKind kind;
  final DateTime date;
  final DateTime? dueDate;
  final String note;
  final String? imagePath;
  final String? contactId;
  final String? contactPhone;
  final bool isSettled;
  final DateTime createdAt;

  DebtEntry copyWith({
    String? person,
    double? amount,
    DebtKind? kind,
    DateTime? date,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? note,
    String? imagePath,
    bool clearImage = false,
    String? contactId,
    String? contactPhone,
    bool clearContact = false,
    bool? isSettled,
  }) {
    return DebtEntry(
      id: id,
      person: person ?? this.person,
      amount: amount ?? this.amount,
      kind: kind ?? this.kind,
      date: date ?? this.date,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      note: note ?? this.note,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      contactId: clearContact ? null : (contactId ?? this.contactId),
      contactPhone: clearContact ? null : (contactPhone ?? this.contactPhone),
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'person': person,
    'amount': amount,
    'kind': kind.name,
    'date': date.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'note': note,
    'imagePath': imagePath,
    'contactId': contactId,
    'contactPhone': contactPhone,
    'isSettled': isSettled,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DebtEntry.fromJson(Map<String, dynamic> json) {
    final kindName = readString(json['kind'], fallback: DebtKind.payable.name);
    return DebtEntry(
      id: _stableFallbackId(json, prefix: 'debt'),
      person: readString(json['person'], fallback: 'Kontak'),
      amount: roundMoney(readDouble(json['amount'])),
      kind: readEnum(DebtKind.values, kindName, DebtKind.payable),
      date: readDate(json['date']),
      dueDate: readNullableDate(json['dueDate']),
      note: readString(json['note']),
      imagePath: readNullableString(json['imagePath']),
      contactId: readNullableString(json['contactId']),
      contactPhone: readNullableString(json['contactPhone']),
      isSettled: readBool(json['isSettled']),
      createdAt: readDate(json['createdAt']),
    );
  }
}
