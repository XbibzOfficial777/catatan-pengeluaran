import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/categories.dart';
import '../core/format.dart';
import '../models/advanced_finance_models.dart';
import '../models/finance_models.dart';
import '../services/image_attachment_service.dart';
import '../widgets/entry_actions.dart';
import '../widgets/form_scaffolding.dart';

class ExpenseFormSheet extends StatefulWidget {
  const ExpenseFormSheet({
    super.key,
    this.entry,
    required this.imageService,
    required this.accounts,
  });
  final ExpenseEntry? entry;
  final ImageAttachmentService imageService;
  final List<MoneyAccount> accounts;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late ExpenseCategory _category;
  late DateTime _date;
  String? _imagePath;
  String? _accountId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.entry?.title ?? '');
    _amount = TextEditingController(
      text: widget.entry == null ? '' : widget.entry!.amount.toStringAsFixed(0),
    );
    _note = TextEditingController(text: widget.entry?.note ?? '');
    _category = widget.entry?.category ?? ExpenseCategory.food;
    _date = widget.entry?.date ?? DateTime.now();
    _imagePath = widget.entry?.imagePath;
    _accountId = widget.entry?.accountId;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => ImageSourceSheet(
        onSelected: (value) => Navigator.pop(sheetContext, value),
      ),
    );
    if (source == null || !mounted) return;
    final newPath = await pickEditStoreImage(
      context,
      widget.imageService,
      source,
    );
    if (newPath == null) return;
    if (_imagePath != null && _imagePath != newPath)
      await widget.imageService.delete(_imagePath);
    if (mounted) setState(() => _imagePath = newPath);
  }

  Future<void> _removeImage() async {
    await widget.imageService.delete(_imagePath);
    if (mounted) setState(() => _imagePath = null);
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih tanggal transaksi',
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  void _save() {
    final title = _title.text.trim();
    final amount = parseAmount(_amount.text);
    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi nama transaksi dan nominal yang valid.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    Navigator.pop(
      context,
      ExpenseEntry(
        id: widget.entry?.id ?? newId(),
        title: title,
        amount: amount,
        category: _category,
        date: _date,
        note: _note.text.trim(),
        imagePath: _imagePath,
        accountId: _accountId,
        recurringId: widget.entry?.recurringId,
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SheetShell(
      title: widget.entry == null ? 'Catat pengeluaran' : 'Edit pengeluaran',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Untuk apa pengeluaran ini?',
              hintText: 'Contoh: Makan siang, ongkos, pulsa',
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Nominal',
              prefixText: 'Rp  ',
              hintText: '0',
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ExpenseCategory>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: ExpenseCategory.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(categoryLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(15),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(formatDate(_date)),
                  ),
                ),
              ),
            ],
          ),
          if (widget.accounts.isNotEmpty) ...[
            const SizedBox(height: 13),
            DropdownButtonFormField<String>(
              value: _accountId,
              decoration: const InputDecoration(labelText: 'Sumber dana'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Uang Saku'),
                ),
                ...widget.accounts
                    .where((item) => !item.isArchived)
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    ),
              ],
              onChanged: (value) => setState(() => _accountId = value),
            ),
          ],
          const SizedBox(height: 13),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Tambahkan detail transaksi',
            ),
          ),
          const SizedBox(height: 15),
          PhotoAttachment(
            path: _imagePath,
            onAdd: _chooseImage,
            onRemove: _removeImage,
            colors: colors,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 53,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                widget.entry == null
                    ? 'Simpan pengeluaran'
                    : 'Simpan perubahan',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
