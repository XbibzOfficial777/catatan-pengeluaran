import 'package:flutter/material.dart';

import '../models/advanced_finance_models.dart';
import '../models/finance_models.dart';

class ExpenseFilterDialog extends StatefulWidget {
  const ExpenseFilterDialog({
    super.key,
    required this.filter,
    required this.accounts,
  });
  final ExpenseFilter filter;
  final List<MoneyAccount> accounts;
  @override
  State<ExpenseFilterDialog> createState() => _ExpenseFilterDialogState();
}

class _ExpenseFilterDialogState extends State<ExpenseFilterDialog> {
  ExpenseCategory? _category;
  String? _accountId;
  DateTime? _from;
  DateTime? _to;
  late final TextEditingController _minimum;
  late final TextEditingController _maximum;

  @override
  void initState() {
    super.initState();
    _category = widget.filter.category;
    _accountId = widget.filter.accountId;
    _from = widget.filter.from;
    _to = widget.filter.to;
    _minimum = TextEditingController(
      text: widget.filter.minimum?.toStringAsFixed(0) ?? '',
    );
    _maximum = TextEditingController(
      text: widget.filter.maximum?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool from}) async {
    final result = await showDatePicker(
      context: context,
      initialDate: from ? (_from ?? DateTime.now()) : (_to ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (from)
        _from = result;
      else
        _to = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter pengeluaran'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ExpenseCategory?>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [
                const DropdownMenuItem<ExpenseCategory?>(
                  value: null,
                  child: Text('Semua kategori'),
                ),
                ...ExpenseCategory.values.map(
                  (item) => DropdownMenuItem<ExpenseCategory?>(
                    value: item,
                    child: Text(_label(item)),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _category = value),
            ),
            if (widget.accounts.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _accountId,
                decoration: const InputDecoration(labelText: 'Akun'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Semua akun'),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(from: true),
                    icon: const Icon(Icons.calendar_today_outlined, size: 17),
                    label: Text(
                      _from == null
                          ? 'Dari'
                          : '${_from!.day}/${_from!.month}/${_from!.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(from: false),
                    icon: const Icon(Icons.event_outlined, size: 17),
                    label: Text(
                      _to == null
                          ? 'Sampai'
                          : '${_to!.day}/${_to!.month}/${_to!.year}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minimum,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Min. nominal',
                      prefixText: 'Rp ',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _maximum,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Maks. nominal',
                      prefixText: 'Rp ',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, const ExpenseFilter()),
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            ExpenseFilter(
              query: widget.filter.query,
              category: _category,
              accountId: _accountId,
              from: _from,
              to: _to,
              minimum: _parse(_minimum.text),
              maximum: _parse(_maximum.text),
            ),
          ),
          child: const Text('Terapkan'),
        ),
      ],
    );
  }

  String _label(ExpenseCategory category) => switch (category) {
    ExpenseCategory.food => 'Makan',
    ExpenseCategory.transport => 'Transportasi',
    ExpenseCategory.shopping => 'Belanja',
    ExpenseCategory.bills => 'Tagihan',
    ExpenseCategory.health => 'Kesehatan',
    ExpenseCategory.entertainment => 'Hiburan',
    ExpenseCategory.other => 'Lainnya',
  };
  double? _parse(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.'));
  }
}
