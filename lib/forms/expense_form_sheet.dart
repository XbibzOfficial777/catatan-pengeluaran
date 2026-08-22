import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/format.dart';
import '../models/advanced_finance_models.dart';
import '../models/finance_models.dart';
import '../services/category_rules_service.dart';
import '../services/image_attachment_service.dart';
import '../services/receipt_ocr_service.dart';
import '../widgets/entry_actions.dart';
import '../widgets/form_scaffolding.dart';

class ExpenseFormSheet extends StatefulWidget {
  const ExpenseFormSheet({
    super.key,
    this.entry,
    required this.imageService,
    required this.accounts,
    this.categoryRules = const <MerchantCategoryRule>[],
  });
  final ExpenseEntry? entry;
  final ImageAttachmentService imageService;
  final List<MoneyAccount> accounts;
  final List<MerchantCategoryRule> categoryRules;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late final TextEditingController _merchant;
  late final TextEditingController _receiptText;
  late final TextEditingController _taxAmount;
  late ExpenseCategory _category;
  late DateTime _date;
  String? _imagePath;
  String? _accountId;
  bool _saving = false;
  bool _isBusiness = false;
  bool _taxDeductible = false;
  bool _scanningReceipt = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.entry?.title ?? '');
    _amount = TextEditingController(
      text: widget.entry == null ? '' : widget.entry!.amount.toStringAsFixed(0),
    );
    _note = TextEditingController(text: widget.entry?.note ?? '');
    _merchant = TextEditingController(text: widget.entry?.merchantName ?? '');
    _receiptText = TextEditingController(text: widget.entry?.receiptText ?? '');
    _taxAmount = TextEditingController(
      text: widget.entry == null || widget.entry!.taxAmount <= 0
          ? ''
          : widget.entry!.taxAmount.toStringAsFixed(0),
    );
    _category = widget.entry?.category ?? ExpenseCategory.other;
    _isBusiness = widget.entry?.isBusiness ?? false;
    _taxDeductible = widget.entry?.taxDeductible ?? false;
    _date = widget.entry?.date ?? DateTime.now();
    _imagePath = widget.entry?.imagePath;
    _accountId = widget.entry?.accountId;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    _merchant.dispose();
    _receiptText.dispose();
    _taxAmount.dispose();
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

  Future<void> _scanReceipt() async {
    if (_imagePath == null) {
      await _chooseImage();
    }
    if (_imagePath == null || !mounted) return;
    setState(() => _scanningReceipt = true);
    try {
      final result = await ReceiptOcrService.instance.scanFile(_imagePath!);
      if (!mounted) return;
      if (result.merchant != null && result.merchant!.isNotEmpty) {
        _merchant.text = result.merchant!;
      }
      if (result.amount != null && result.amount! > 0) {
        _amount.text = result.amount!.toStringAsFixed(0);
      }
      if (result.date != null) _date = result.date!;
      if (result.text.isNotEmpty) _receiptText.text = result.text;
      _category = CategoryRulesService.suggest(
        title: _title.text,
        merchant: _merchant.text,
        rules: widget.categoryRules,
      );
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Struk berhasil dibaca. Periksa kembali hasil OCR sebelum menyimpan.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OCR tidak dapat digunakan: $error')),
      );
    } finally {
      if (mounted) setState(() => _scanningReceipt = false);
    }
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
    final suggestedCategory = CategoryRulesService.suggest(
      title: title,
      merchant: _merchant.text,
      rules: widget.categoryRules,
    );
    if (_category == ExpenseCategory.other &&
        suggestedCategory != ExpenseCategory.other) {
      _category = suggestedCategory;
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
        merchantName: _merchant.text.trim(),
        receiptText: _receiptText.text.trim(),
        isBusiness: _isBusiness,
        taxDeductible: _taxDeductible,
        taxAmount: parseAmount(_taxAmount.text),
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
            controller: _merchant,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Merchant/toko (opsional)',
              hintText: 'Contoh: Warung, Tokopedia, PLN',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            onChanged: (value) {
              if (_category == ExpenseCategory.other) {
                setState(() {
                  _category = CategoryRulesService.suggest(
                    title: _title.text,
                    merchant: value,
                    rules: widget.categoryRules,
                  );
                });
              }
            },
          ),
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
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _scanningReceipt ? null : _scanReceipt,
              icon: _scanningReceipt
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.document_scanner_outlined),
              label: Text(
                _scanningReceipt ? 'Membaca struk...' : 'Scan struk dengan OCR',
              ),
            ),
          ),
          if (_receiptText.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _receiptText,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Teks struk (hasil OCR)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
          ],
          const SizedBox(height: 10),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Transaksi bisnis/usaha'),
            subtitle: const Text(
              'Pisahkan dari pengeluaran pribadi pada laporan.',
            ),
            value: _isBusiness,
            onChanged: (value) => setState(() => _isBusiness = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dapat dikurangkan dari pajak'),
            value: _taxDeductible,
            onChanged: (value) => setState(() => _taxDeductible = value),
          ),
          if (_taxDeductible) ...[
            const SizedBox(height: 4),
            TextField(
              controller: _taxAmount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Nominal pajak (opsional)',
                prefixText: 'Rp  ',
              ),
            ),
          ],
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
