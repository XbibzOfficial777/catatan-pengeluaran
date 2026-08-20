import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/advanced_finance_models.dart';
import '../models/finance_models.dart';

const _brandOptions = <String, String>{
  'wallet': 'Dompet umum',
  'gopay': 'GoPay',
  'ovo': 'OVO',
  'dana': 'DANA',
  'linkaja': 'LinkAja',
};

String categoryLabel(ExpenseCategory category) => switch (category) {
  ExpenseCategory.food => 'Makan',
  ExpenseCategory.transport => 'Transportasi',
  ExpenseCategory.shopping => 'Belanja',
  ExpenseCategory.bills => 'Tagihan',
  ExpenseCategory.health => 'Kesehatan',
  ExpenseCategory.entertainment => 'Hiburan',
  ExpenseCategory.other => 'Lainnya',
};

class BudgetSettingsSheet extends StatefulWidget {
  const BudgetSettingsSheet({super.key, required this.initialBudgets});
  final List<BudgetLimit> initialBudgets;
  @override
  State<BudgetSettingsSheet> createState() => _BudgetSettingsSheetState();
}

class _BudgetSettingsSheetState extends State<BudgetSettingsSheet> {
  late List<BudgetLimit> _items;
  @override
  void initState() {
    super.initState();
    _items = [...widget.initialBudgets];
  }

  Future<void> _edit({BudgetLimit? budget}) async {
    final result = await showDialog<BudgetLimit>(
      context: context,
      builder: (_) => BudgetEditorDialog(budget: budget),
    );
    if (result == null || !mounted) return;
    setState(() {
      final index = _items.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        _items.add(result);
      } else {
        _items[index] = result;
      }
    });
  }

  Future<void> _delete(BudgetLimit budget) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus anggaran?'),
        content: Text('Batas ${categoryLabel(budget.category)} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true && mounted)
      setState(() => _items.removeWhere((item) => item.id == budget.id));
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Anggaran bulanan',
      subtitle: 'Tetapkan batas per kategori dan ambang peringatan.',
      action: IconButton.filledTonal(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_items.isEmpty)
            const _EmptySetting(text: 'Belum ada anggaran kategori.'),
          ..._items.map(
            (budget) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(categoryLabel(budget.category).substring(0, 1)),
                ),
                title: Text(
                  categoryLabel(budget.category),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'Batas ${_currency(budget.monthlyLimit)} • Peringatan ${budget.alertPercent}%',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: budget.enabled,
                      onChanged: (value) => setState(
                        () => _items[_items.indexOf(budget)] = budget.copyWith(
                          enabled: value,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _edit(budget: budget);
                        if (value == 'delete') _delete(budget);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _items),
              child: const Text('Simpan anggaran'),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountSettingsSheet extends StatefulWidget {
  const AccountSettingsSheet({
    super.key,
    required this.initialAccounts,
    required this.expenses,
    required this.recurring,
  });
  final List<MoneyAccount> initialAccounts;
  final List<ExpenseEntry> expenses;
  final List<RecurringExpense> recurring;
  @override
  State<AccountSettingsSheet> createState() => _AccountSettingsSheetState();
}

class _AccountSettingsSheetState extends State<AccountSettingsSheet> {
  late List<MoneyAccount> _items;

  @override
  void initState() {
    super.initState();
    _items = [...widget.initialAccounts];
  }

  Future<void> _edit({MoneyAccount? account}) async {
    if (account != null) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AccountTransitionSplash(account: account),
      );
    }
    final existingNames = _items
        .where((item) => item.id != account?.id)
        .map((item) => normalizeMoneyAccountName(item.name))
        .toSet();
    final result = await showDialog<MoneyAccount>(
      context: context,
      builder: (_) =>
          AccountEditorDialog(account: account, existingNames: existingNames),
    );
    if (result == null || !mounted) return;
    setState(() {
      final index = _items.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        _items.add(result);
      } else {
        _items[index] = result;
      }
    });
  }

  Future<void> _archive(MoneyAccount account) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arsipkan akun?'),
        content: Text('Akun ${account.name} tetap ada di riwayat transaksi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        final index = _items.indexWhere((item) => item.id == account.id);
        if (index != -1) {
          _items[index] = account.copyWith(isArchived: true);
        }
      });
    }
  }

  Future<void> _deletePermanent(MoneyAccount account) async {
    final expenseCount = widget.expenses
        .where((item) => item.accountId == account.id)
        .length;
    final recurringCount = widget.recurring
        .where((item) => item.accountId == account.id)
        .length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${account.name} permanen?'),
        content: Text(
          expenseCount + recurringCount == 0
              ? 'Akun ini akan dihapus dari daftar akun.'
              : 'Akun dihapus, tetapi $expenseCount transaksi dan $recurringCount transaksi berulang tetap disimpan tanpa akun.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus permanen'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final updated = [..._items]..removeWhere((item) => item.id == account.id);
      Navigator.pop(context, updated);
    }
  }

  Future<void> _openDetail(MoneyAccount account) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AccountDetailSheet(
        account: account,
        expenses: widget.expenses,
        onEdit: () => _edit(account: account),
        onDelete: () => _deletePermanent(account),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Akun dan dompet',
      subtitle: 'Pisahkan uang tunai, bank, kartu, dan e-wallet.',
      action: IconButton.filledTonal(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_items.where((item) => !item.isArchived).isEmpty)
            const _EmptySetting(
              text: 'Belum ada akun. Tambahkan akun pertama.',
            ),
          ..._items
              .where((item) => !item.isArchived)
              .map(
                (account) => Card(
                  child: ListTile(
                    onTap: () => _openDetail(account),
                    leading: AccountBrandIcon(brandKey: account.brandKey),
                    title: Text(
                      account.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${account.type.name} • Saldo ${_currency(account.balance)}',
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Kelola ${account.name}',
                      onSelected: (value) {
                        if (value == 'edit') _edit(account: account);
                        if (value == 'archive') _archive(account);
                        if (value == 'delete') _deletePermanent(account);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Ganti akun/dompet'),
                        ),
                        PopupMenuItem(
                          value: 'archive',
                          child: Text('Arsipkan'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Hapus permanen'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context, _items),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Simpan akun dan dompet'),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountDetailSheet extends StatefulWidget {
  const AccountDetailSheet({
    super.key,
    required this.account,
    required this.expenses,
    required this.onEdit,
    required this.onDelete,
  });
  final MoneyAccount account;
  final List<ExpenseEntry> expenses;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<AccountDetailSheet> createState() => _AccountDetailSheetState();
}

class _AccountDetailSheetState extends State<AccountDetailSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final entries =
        widget.expenses
            .where((item) => item.accountId == widget.account.id)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return _SheetFrame(
      title: widget.account.name,
      subtitle: 'Saldo dan riwayat akun ditampilkan terpisah.',
      action: AccountBrandIcon(brandKey: widget.account.brandKey, size: 34),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary,
                      colors.primary.withValues(alpha: 0.72),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo ${widget.account.type.name}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currency(widget.account.balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onEdit();
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Ganti'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDelete();
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Hapus'),
                    style: FilledButton.styleFrom(
                      foregroundColor: colors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Riwayat pengeluaran',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const _EmptySetting(text: 'Belum ada pengeluaran dari akun ini.')
            else
              ...entries.map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colors.error.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: colors.error,
                    ),
                  ),
                  title: Text(entry.title),
                  subtitle: Text(
                    '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                  ),
                  trailing: Text(
                    _currency(entry.amount),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AccountTransitionSplash extends StatefulWidget {
  const AccountTransitionSplash({super.key, required this.account});
  final MoneyAccount account;

  @override
  State<AccountTransitionSplash> createState() =>
      _AccountTransitionSplashState();
}

class _AccountTransitionSplashState extends State<AccountTransitionSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AccountBrandIcon(brandKey: widget.account.brandKey, size: 48),
              const SizedBox(height: 12),
              Text(
                'Membuka ${widget.account.name}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class RecurringSettingsSheet extends StatefulWidget {
  const RecurringSettingsSheet({
    super.key,
    required this.initialItems,
    required this.accounts,
  });
  final List<RecurringExpense> initialItems;
  final List<MoneyAccount> accounts;
  @override
  State<RecurringSettingsSheet> createState() => _RecurringSettingsSheetState();
}

class _RecurringSettingsSheetState extends State<RecurringSettingsSheet> {
  late List<RecurringExpense> _items;
  @override
  void initState() {
    super.initState();
    _items = [...widget.initialItems];
  }

  Future<void> _edit({RecurringExpense? item}) async {
    final result = await showDialog<RecurringExpense>(
      context: context,
      builder: (_) =>
          RecurringEditorDialog(item: item, accounts: widget.accounts),
    );
    if (result == null || !mounted) return;
    setState(() {
      final index = _items.indexWhere((entry) => entry.id == result.id);
      if (index == -1) {
        _items.add(result);
      } else {
        _items[index] = result;
      }
    });
  }

  Future<void> _delete(RecurringExpense item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus transaksi berulang?'),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true && mounted)
      setState(() => _items.removeWhere((entry) => entry.id == item.id));
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Transaksi berulang',
      subtitle: 'Buat pengeluaran nyata saat jatuh tempo, bukan simulasi.',
      action: IconButton.filledTonal(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_items.isEmpty)
            const _EmptySetting(text: 'Belum ada transaksi berulang.'),
          ..._items.map(
            (item) => Card(
              child: ListTile(
                leading: const Icon(Icons.autorenew_rounded),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${_currency(item.amount)} • Berikutnya ${item.nextDue.day}/${item.nextDue.month}/${item.nextDue.year}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: item.enabled,
                      onChanged: (value) => setState(
                        () => _items[_items.indexOf(item)] = item.copyWith(
                          enabled: value,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _edit(item: item);
                        if (value == 'delete') _delete(item);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _items),
              child: const Text('Simpan transaksi berulang'),
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetEditorDialog extends StatefulWidget {
  const BudgetEditorDialog({super.key, this.budget});
  final BudgetLimit? budget;
  @override
  State<BudgetEditorDialog> createState() => _BudgetEditorDialogState();
}

class _BudgetEditorDialogState extends State<BudgetEditorDialog> {
  late ExpenseCategory _category;
  late final TextEditingController _amount;
  late double _alert;
  @override
  void initState() {
    super.initState();
    _category = widget.budget?.category ?? ExpenseCategory.food;
    _amount = TextEditingController(
      text: widget.budget == null
          ? ''
          : widget.budget!.monthlyLimit.toStringAsFixed(0),
    );
    _alert = (widget.budget?.alertPercent ?? 80).toDouble();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.budget == null ? 'Tambah anggaran' : 'Edit anggaran'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<ExpenseCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Kategori'),
            items: ExpenseCategory.values
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(categoryLabel(item)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Batas per bulan',
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Peringatan'),
              Expanded(
                child: Slider(
                  value: _alert,
                  min: 50,
                  max: 100,
                  divisions: 10,
                  label: '${_alert.round()}%',
                  onChanged: (value) => setState(() => _alert = value),
                ),
              ),
              Text('${_alert.round()}%'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final amount = _parseAmount(_amount.text);
            if (amount <= 0) return;
            final old = widget.budget;
            Navigator.pop(
              context,
              BudgetLimit(
                id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                category: _category,
                monthlyLimit: amount,
                alertPercent: _alert.round(),
                enabled: old?.enabled ?? true,
                createdAt: old?.createdAt ?? DateTime.now(),
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class AccountEditorDialog extends StatefulWidget {
  const AccountEditorDialog({
    super.key,
    this.account,
    this.existingNames = const <String>{},
  });
  final MoneyAccount? account;
  final Set<String> existingNames;
  @override
  State<AccountEditorDialog> createState() => _AccountEditorDialogState();
}

class _AccountEditorDialogState extends State<AccountEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late MoneyAccountType _type;
  late String _brand;
  String? _nameError;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.account?.name ?? '');
    _balance = TextEditingController(
      text: widget.account?.balance.toStringAsFixed(0) ?? '',
    );
    _type = widget.account?.type ?? MoneyAccountType.cash;
    _brand = widget.account?.brandKey ?? 'wallet';
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.account == null ? 'Tambah akun' : 'Edit akun'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'Nama akun',
                hintText: 'Contoh: GoPay utama',
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _balance,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Saldo awal',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MoneyAccountType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Jenis akun'),
              items: MoneyAccountType.values
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.name)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _brand,
              decoration: const InputDecoration(labelText: 'Logo brand'),
              items: _brandOptions.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Row(
                        children: [
                          if (entry.key != 'wallet')
                            AccountBrandIcon(brandKey: entry.key, size: 22),
                          if (entry.key == 'wallet')
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 22,
                            ),
                          const SizedBox(width: 8),
                          Text(entry.value),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _brand = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) {
              setState(() => _nameError = 'Nama akun wajib diisi.');
              return;
            }
            if (widget.existingNames.contains(
              normalizeMoneyAccountName(name),
            )) {
              setState(() => _nameError = 'Nama akun sudah digunakan.');
              return;
            }
            final old = widget.account;
            Navigator.pop(
              context,
              MoneyAccount(
                id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                name: name,
                type: _type,
                balance: _parseAmount(_balance.text),
                brandKey: _brand,
                isArchived: old?.isArchived ?? false,
                createdAt: old?.createdAt ?? DateTime.now(),
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class RecurringEditorDialog extends StatefulWidget {
  const RecurringEditorDialog({super.key, this.item, required this.accounts});
  final RecurringExpense? item;
  final List<MoneyAccount> accounts;
  @override
  State<RecurringEditorDialog> createState() => _RecurringEditorDialogState();
}

class _RecurringEditorDialogState extends State<RecurringEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _day;
  late ExpenseCategory _category;
  String? _accountId;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.item?.title ?? '');
    _amount = TextEditingController(
      text: widget.item?.amount.toStringAsFixed(0) ?? '',
    );
    _day = TextEditingController(
      text: '${widget.item?.dayOfMonth ?? DateTime.now().day}',
    );
    _category = widget.item?.category ?? ExpenseCategory.bills;
    _accountId = widget.item?.accountId;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _day.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.item == null
            ? 'Tambah transaksi berulang'
            : 'Edit transaksi berulang',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Nama',
                hintText: 'Contoh: Internet rumah',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: ExpenseCategory.values
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(categoryLabel(item)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _day,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tanggal setiap bulan',
                suffixText: '(1–31)',
              ),
            ),
            if (widget.accounts.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _accountId,
                decoration: const InputDecoration(labelText: 'Akun sumber'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tidak ditentukan'),
                  ),
                  ...widget.accounts
                      .where((item) => !item.isArchived)
                      .map(
                        (item) => DropdownMenuItem<String?>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      ),
                ],
                onChanged: (value) => setState(() => _accountId = value),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final title = _title.text.trim();
            final amount = _parseAmount(_amount.text);
            final day = (int.tryParse(_day.text) ?? 1).clamp(1, 31);
            if (title.isEmpty || amount <= 0) return;
            final old = widget.item;
            final due =
                old?.nextDue ??
                DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  day.clamp(1, 28),
                );
            Navigator.pop(
              context,
              RecurringExpense(
                id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                title: title,
                amount: amount,
                category: _category,
                accountId: _accountId,
                dayOfMonth: day,
                nextDue: due,
                note: old?.note ?? '',
                enabled: old?.enabled ?? true,
                createdAt: old?.createdAt ?? DateTime.now(),
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget action;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: colors.onSurface.withValues(alpha: 0.62),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  action,
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySetting extends StatelessWidget {
  const _EmptySetting({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text),
  );
}

class AccountBrandIcon extends StatelessWidget {
  const AccountBrandIcon({required this.brandKey, this.size = 30});
  final String brandKey;
  final double size;
  @override
  Widget build(BuildContext context) {
    if (brandKey == 'wallet')
      return Icon(Icons.account_balance_wallet_outlined, size: size);
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'assets/brands/$brandKey.svg',
        fit: BoxFit.contain,
        placeholderBuilder: (_) =>
            Icon(Icons.account_balance_wallet_outlined, size: size),
      ),
    );
  }
}

String _currency(double value) =>
    'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (_) => '.')}';
double _parseAmount(String value) =>
    double.tryParse(value.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
