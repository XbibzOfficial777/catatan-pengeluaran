import 'finance_models.dart';
import 'json_helpers.dart';

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

  double get progress =>
      targetAmount <= 0 ? 0 : clampProgress(savedAmount / targetAmount);

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
    id: readString(
      json['id'],
      fallback: DateTime.now().microsecondsSinceEpoch.toString(),
    ),
    name: readString(json['name'], fallback: 'Tabungan'),
    targetAmount: roundMoney(readDouble(json['targetAmount'])),
    savedAmount: roundMoney(readDouble(json['savedAmount'])),
    photoPath: readNullableString(json['photoPath']),
    reminderEnabled: readBool(json['reminderEnabled']),
    reminderHour: clampInt(readInt(json['reminderHour'], fallback: 20), 0, 23),
    reminderMinute: clampInt(readInt(json['reminderMinute']), 0, 59),
    createdAt: readDate(json['createdAt']),
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
    id: readString(
      json['id'],
      fallback: DateTime.now().microsecondsSinceEpoch.toString(),
    ),
    name: readString(json['name'], fallback: 'Dompet'),
    type: readEnum(
      MoneyAccountType.values,
      json['type'],
      MoneyAccountType.cash,
    ),
    balance: roundMoney(readDouble(json['balance'])),
    brandKey: readString(json['brandKey'], fallback: 'wallet'),
    isArchived: readBool(json['isArchived']),
    createdAt: readDate(json['createdAt']),
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
    id: readString(
      json['id'],
      fallback: DateTime.now().microsecondsSinceEpoch.toString(),
    ),
    category: readEnum(
      ExpenseCategory.values,
      json['category'],
      ExpenseCategory.other,
    ),
    monthlyLimit: roundMoney(readDouble(json['monthlyLimit'])),
    alertPercent: clampInt(readInt(json['alertPercent'], fallback: 80), 0, 100),
    enabled: readBool(json['enabled'], fallback: true),
    createdAt: readDate(json['createdAt']),
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

  factory RecurringExpense.fromJson(Map<String, dynamic> json) =>
      RecurringExpense(
        id: readString(
          json['id'],
          fallback: DateTime.now().microsecondsSinceEpoch.toString(),
        ),
        title: readString(json['title'], fallback: 'Transaksi berulang'),
        amount: roundMoney(readDouble(json['amount'])),
        category: readEnum(
          ExpenseCategory.values,
          json['category'],
          ExpenseCategory.other,
        ),
        accountId: readNullableString(json['accountId']),
        dayOfMonth: clampInt(readInt(json['dayOfMonth'], fallback: 1), 1, 31),
        note: readString(json['note']),
        enabled: readBool(json['enabled'], fallback: true),
        nextDue: readDate(json['nextDue']),
        createdAt: readDate(json['createdAt']),
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

class SplitParticipant {
  const SplitParticipant({
    required this.id,
    required this.name,
    required this.amount,
    this.isPaid = false,
  });

  final String id;
  final String name;
  final double amount;
  final bool isPaid;

  SplitParticipant copyWith({String? name, double? amount, bool? isPaid}) =>
      SplitParticipant(
        id: id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        isPaid: isPaid ?? this.isPaid,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'isPaid': isPaid,
  };

  factory SplitParticipant.fromJson(Map<String, dynamic> json) =>
      SplitParticipant(
        id: readString(
          json['id'],
          fallback: DateTime.now().microsecondsSinceEpoch.toString(),
        ),
        name: readString(json['name'], fallback: 'Peserta'),
        amount: roundMoney(readDouble(json['amount'])),
        isPaid: readBool(json['isPaid']),
      );
}

class SplitBill {
  const SplitBill({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.date,
    this.participants = const <SplitParticipant>[],
    this.expenseIds = const <String>[],
    this.note = '',
    required this.createdAt,
  });

  final String id;
  final String title;
  final double totalAmount;
  final DateTime date;
  final List<SplitParticipant> participants;
  final List<String> expenseIds;
  final String note;
  final DateTime createdAt;

  double get assignedAmount => participants.fold<double>(
    0,
    (sum, participant) => sum + participant.amount,
  );

  double get remainingAmount => roundMoney(totalAmount - assignedAmount);

  bool get isBalanced => remainingAmount.abs() < 0.01;

  SplitBill copyWith({
    String? title,
    double? totalAmount,
    DateTime? date,
    List<SplitParticipant>? participants,
    List<String>? expenseIds,
    String? note,
  }) => SplitBill(
    id: id,
    title: title ?? this.title,
    totalAmount: totalAmount ?? this.totalAmount,
    date: date ?? this.date,
    participants: participants ?? this.participants,
    expenseIds: expenseIds ?? this.expenseIds,
    note: note ?? this.note,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'totalAmount': totalAmount,
    'date': date.toIso8601String(),
    'participants': participants.map((item) => item.toJson()).toList(),
    'expenseIds': expenseIds,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SplitBill.fromJson(Map<String, dynamic> json) => SplitBill(
    id: readString(
      json['id'],
      fallback: DateTime.now().microsecondsSinceEpoch.toString(),
    ),
    title: readString(json['title'], fallback: 'Split bill'),
    totalAmount: roundMoney(readDouble(json['totalAmount'])),
    date: readDate(json['date']),
    participants: readList<SplitParticipant>(
      json['participants'],
      SplitParticipant.fromJson,
    ),
    expenseIds: readStringList(json['expenseIds']),
    note: readString(json['note']),
    createdAt: readDate(json['createdAt']),
  );
}

class ReconciliationSnapshot {
  const ReconciliationSnapshot({
    required this.id,
    required this.accountId,
    required this.checkedAt,
    required this.expectedBalance,
    required this.actualBalance,
    this.note = '',
    required this.createdAt,
  });

  final String id;
  final String accountId;
  final DateTime checkedAt;
  final double expectedBalance;
  final double actualBalance;
  final String note;
  final DateTime createdAt;

  double get difference => roundMoney(actualBalance - expectedBalance);

  Map<String, dynamic> toJson() => {
    'id': id,
    'accountId': accountId,
    'checkedAt': checkedAt.toIso8601String(),
    'expectedBalance': expectedBalance,
    'actualBalance': actualBalance,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ReconciliationSnapshot.fromJson(Map<String, dynamic> json) =>
      ReconciliationSnapshot(
        id: readString(
          json['id'],
          fallback: DateTime.now().microsecondsSinceEpoch.toString(),
        ),
        accountId: readString(json['accountId']),
        checkedAt: readDate(json['checkedAt']),
        expectedBalance: roundMoney(readDouble(json['expectedBalance'])),
        actualBalance: roundMoney(readDouble(json['actualBalance'])),
        note: readString(json['note']),
        createdAt: readDate(json['createdAt']),
      );
}

class MerchantCategoryRule {
  const MerchantCategoryRule({
    required this.id,
    required this.pattern,
    required this.category,
    this.enabled = true,
    required this.createdAt,
  });

  final String id;
  final String pattern;
  final ExpenseCategory category;
  final bool enabled;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'pattern': pattern,
    'category': category.name,
    'enabled': enabled,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MerchantCategoryRule.fromJson(Map<String, dynamic> json) =>
      MerchantCategoryRule(
        id: readString(
          json['id'],
          fallback: DateTime.now().microsecondsSinceEpoch.toString(),
        ),
        pattern: readString(json['pattern']),
        category: readEnum(
          ExpenseCategory.values,
          json['category'],
          ExpenseCategory.other,
        ),
        enabled: readBool(json['enabled'], fallback: true),
        createdAt: readDate(json['createdAt']),
      );
}
