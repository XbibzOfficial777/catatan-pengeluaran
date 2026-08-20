import 'finance_models.dart';

enum MoneyAccountType { cash, bank, ewallet, card }

String normalizeMoneyAccountName(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    this.photoPath,
    this.reminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    required this.createdAt,
  });

  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final String? photoPath;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final DateTime createdAt;

  double get progress => targetAmount <= 0
      ? 0
      : (savedAmount / targetAmount).clamp(0, 1).toDouble();

  bool get isComplete => targetAmount > 0 && savedAmount >= targetAmount;

  SavingsGoal copyWith({
    String? name,
    double? targetAmount,
    double? savedAmount,
    String? photoPath,
    bool clearPhoto = false,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) => SavingsGoal(
    id: id,
    name: name ?? this.name,
    targetAmount: targetAmount ?? this.targetAmount,
    savedAmount: savedAmount ?? this.savedAmount,
    photoPath: clearPhoto ? null : photoPath ?? this.photoPath,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'targetAmount': targetAmount,
    'savedAmount': savedAmount,
    'photoPath': photoPath,
    'reminderEnabled': reminderEnabled,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
    id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
    name: json['name'] as String? ?? 'Tabungan',
    targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
    savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0,
    photoPath: json['photoPath'] as String?,
    reminderEnabled: json['reminderEnabled'] as bool? ?? false,
    reminderHour: ((json['reminderHour'] as num?)?.toInt() ?? 20).clamp(0, 23),
    reminderMinute: ((json['reminderMinute'] as num?)?.toInt() ?? 0).clamp(0, 59),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class MoneyAccount {
  const MoneyAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.brandKey = 'wallet',
    this.isArchived = false,
    required this.createdAt,
  });

  final String id;
  final String name;
  final MoneyAccountType type;
  final double balance;
  final String brandKey;
  final bool isArchived;
  final DateTime createdAt;

  MoneyAccount copyWith({
    String? name,
    MoneyAccountType? type,
    double? balance,
    String? brandKey,
    bool? isArchived,
  }) => MoneyAccount(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    balance: balance ?? this.balance,
    brandKey: brandKey ?? this.brandKey,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'balance': balance,
    'brandKey': brandKey,
    'isArchived': isArchived,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MoneyAccount.fromJson(Map<String, dynamic> json) => MoneyAccount(
    id:
        json['id'] as String? ??
        DateTime.now().microsecondsSinceEpoch.toString(),
    name: json['name'] as String? ?? 'Dompet',
    type: MoneyAccountType.values.firstWhere(
      (item) => item.name == json['type'],
      orElse: () => MoneyAccountType.cash,
    ),
    balance: (json['balance'] as num?)?.toDouble() ?? 0,
    brandKey: json['brandKey'] as String? ?? 'wallet',
    isArchived: json['isArchived'] as bool? ?? false,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class BudgetLimit {
  const BudgetLimit({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    this.alertPercent = 80,
    this.enabled = true,
    required this.createdAt,
  });

  final String id;
  final ExpenseCategory category;
  final double monthlyLimit;
  final int alertPercent;
  final bool enabled;
  final DateTime createdAt;

  BudgetLimit copyWith({
    double? monthlyLimit,
    int? alertPercent,
    bool? enabled,
  }) => BudgetLimit(
    id: id,
    category: category,
    monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    alertPercent: alertPercent ?? this.alertPercent,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    'monthlyLimit': monthlyLimit,
    'alertPercent': alertPercent,
    'enabled': enabled,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BudgetLimit.fromJson(Map<String, dynamic> json) => BudgetLimit(
    id:
        json['id'] as String? ??
        DateTime.now().microsecondsSinceEpoch.toString(),
    category: ExpenseCategory.values.firstWhere(
      (item) => item.name == json['category'],
      orElse: () => ExpenseCategory.other,
    ),
    monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble() ?? 0,
    alertPercent: (json['alertPercent'] as num?)?.toInt() ?? 80,
    enabled: json['enabled'] as bool? ?? true,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class RecurringExpense {
  const RecurringExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.accountId,
    this.dayOfMonth = 1,
    this.note = '',
    this.enabled = true,
    required this.nextDue,
    required this.createdAt,
  });

  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final String? accountId;
  final int dayOfMonth;
  final String note;
  final bool enabled;
  final DateTime nextDue;
  final DateTime createdAt;

  RecurringExpense copyWith({
    String? title,
    double? amount,
    ExpenseCategory? category,
    String? accountId,
    bool clearAccount = false,
    int? dayOfMonth,
    String? note,
    bool? enabled,
    DateTime? nextDue,
  }) => RecurringExpense(
    id: id,
    title: title ?? this.title,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    accountId: clearAccount ? null : accountId ?? this.accountId,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    note: note ?? this.note,
    enabled: enabled ?? this.enabled,
    nextDue: nextDue ?? this.nextDue,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category.name,
    'accountId': accountId,
    'dayOfMonth': dayOfMonth,
    'note': note,
    'enabled': enabled,
    'nextDue': nextDue.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory RecurringExpense.fromJson(
    Map<String, dynamic> json,
  ) => RecurringExpense(
    id:
        json['id'] as String? ??
        DateTime.now().microsecondsSinceEpoch.toString(),
    title: json['title'] as String? ?? 'Transaksi berulang',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    category: ExpenseCategory.values.firstWhere(
      (item) => item.name == json['category'],
      orElse: () => ExpenseCategory.other,
    ),
    accountId: json['accountId'] as String?,
    dayOfMonth: (json['dayOfMonth'] as num?)?.clamp(1, 31).toInt() ?? 1,
    note: json['note'] as String? ?? '',
    enabled: json['enabled'] as bool? ?? true,
    nextDue:
        DateTime.tryParse(json['nextDue'] as String? ?? '') ?? DateTime.now(),
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class ExpenseFilter {
  const ExpenseFilter({
    this.query = '',
    this.category,
    this.accountId,
    this.from,
    this.to,
    this.minimum,
    this.maximum,
  });

  final String query;
  final ExpenseCategory? category;
  final String? accountId;
  final DateTime? from;
  final DateTime? to;
  final double? minimum;
  final double? maximum;

  bool get isActive =>
      query.trim().isNotEmpty ||
      category != null ||
      accountId != null ||
      from != null ||
      to != null ||
      minimum != null ||
      maximum != null;

  ExpenseFilter copyWith({
    String? query,
    ExpenseCategory? category,
    bool clearCategory = false,
    String? accountId,
    bool clearAccount = false,
    DateTime? from,
    bool clearFrom = false,
    DateTime? to,
    bool clearTo = false,
    double? minimum,
    bool clearMinimum = false,
    double? maximum,
    bool clearMaximum = false,
  }) => ExpenseFilter(
    query: query ?? this.query,
    category: clearCategory ? null : category ?? this.category,
    accountId: clearAccount ? null : accountId ?? this.accountId,
    from: clearFrom ? null : from ?? this.from,
    to: clearTo ? null : to ?? this.to,
    minimum: clearMinimum ? null : minimum ?? this.minimum,
    maximum: clearMaximum ? null : maximum ?? this.maximum,
  );
}
