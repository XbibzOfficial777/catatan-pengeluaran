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
    'isSettled': isSettled,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) {
    final categoryName =
        json['category'] as String? ?? ExpenseCategory.other.name;
    return ExpenseEntry(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Pengeluaran',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: ExpenseCategory.values.firstWhere(
        (value) => value.name == categoryName,
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      accountId: json['accountId'] as String?,
      recurringId: json['recurringId'] as String?,
      isSettled: json.containsKey('isSettled')
          ? json['isSettled'] as bool? ?? false
          : true,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
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
    final kindName = json['kind'] as String? ?? DebtKind.payable.name;
    return DebtEntry(
      id: json['id'] as String,
      person: json['person'] as String? ?? 'Kontak',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      kind: DebtKind.values.firstWhere(
        (value) => value.name == kindName,
        orElse: () => DebtKind.payable,
      ),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? ''),
      note: json['note'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      contactId: json['contactId'] as String?,
      contactPhone: json['contactPhone'] as String?,
      isSettled: json['isSettled'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
