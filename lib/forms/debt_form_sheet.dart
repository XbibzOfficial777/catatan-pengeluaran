import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/format.dart';
import '../core/palette.dart';
import '../models/finance_models.dart';
import '../services/contact_service.dart';
import '../services/image_attachment_service.dart';
import '../widgets/entry_actions.dart';
import '../widgets/form_scaffolding.dart';

class DebtFormSheet extends StatefulWidget {
  const DebtFormSheet({
    super.key,
    this.entry,
    required this.imageService,
    required this.contactService,
  });
  final DebtEntry? entry;
  final ImageAttachmentService imageService;
  final ContactService contactService;

  @override
  State<DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends State<DebtFormSheet> {
  late final TextEditingController _person;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late DebtKind _kind;
  late DateTime _date;
  DateTime? _dueDate;
  String? _imagePath;
  String? _contactId;
  String? _contactPhone;
  bool _contactBusy = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _person = TextEditingController(text: widget.entry?.person ?? '');
    _amount = TextEditingController(
      text: widget.entry == null ? '' : widget.entry!.amount.toStringAsFixed(0),
    );
    _note = TextEditingController(text: widget.entry?.note ?? '');
    _kind = widget.entry?.kind ?? DebtKind.payable;
    _date = widget.entry?.date ?? DateTime.now();
    _dueDate = widget.entry?.dueDate;
    _imagePath = widget.entry?.imagePath;
    _contactId = widget.entry?.contactId;
    _contactPhone = widget.entry?.contactPhone;
  }

  @override
  void dispose() {
    _person.dispose();
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

  Future<void> _pickContact() async {
    setState(() => _contactBusy = true);
    try {
      final selected = await widget.contactService.pickContact();
      if (!mounted) return;
      if (selected == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kontak tidak dipilih atau izin kontak belum diberikan.',
            ),
          ),
        );
        return;
      }
      setState(() {
        _contactId = selected.id;
        _contactPhone = selected.phone;
        _person.text = selected.name;
      });
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kontak belum bisa diakses. Coba lagi.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _contactBusy = false);
    }
  }

  void _clearContact() {
    setState(() {
      _contactId = null;
      _contactPhone = null;
    });
  }

  Future<void> _pickDate({required bool due}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: due ? (_dueDate ?? _date) : _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: due ? 'Pilih jatuh tempo' : 'Pilih tanggal hutang',
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (due) {
        _dueDate = selected;
      } else {
        _date = selected;
      }
    });
  }

  void _save() {
    final person = _person.text.trim();
    final amount = parseAmount(_amount.text);
    if (person.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama orang dan nominal yang valid.')),
      );
      return;
    }
    setState(() => _saving = true);
    Navigator.pop(
      context,
      DebtEntry(
        id: widget.entry?.id ?? newId(),
        person: person,
        amount: amount,
        kind: _kind,
        date: _date,
        dueDate: _dueDate,
        note: _note.text.trim(),
        imagePath: _imagePath,
        contactId: _contactId,
        contactPhone: _contactPhone,
        isSettled: widget.entry?.isSettled ?? false,
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SheetShell(
      title: widget.entry == null ? 'Tambah hutang' : 'Edit catatan hutang',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<DebtKind>(
            segments: const [
              ButtonSegment(
                value: DebtKind.payable,
                label: Text('Saya berhutang'),
                icon: Icon(Icons.arrow_upward_rounded),
              ),
              ButtonSegment(
                value: DebtKind.receivable,
                label: Text('Dipinjam orang'),
                icon: Icon(Icons.arrow_downward_rounded),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (value) => setState(() => _kind = value.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _person,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Nama orang',
              hintText: 'Ketik manual atau pilih kontak',
              suffixIcon: _contactBusy
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Pilih dari kontak',
                      onPressed: _pickContact,
                      icon: const Icon(Icons.contacts_outlined),
                    ),
            ),
          ),
          if (_contactId != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _contactPhone?.isNotEmpty == true
                          ? _contactPhone!
                          : 'Nomor tidak tersedia',
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.68),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearContact,
                    child: const Text(
                      'Lepas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                child: InkWell(
                  onTap: () => _pickDate(due: false),
                  borderRadius: BorderRadius.circular(15),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      suffixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(formatDate(_date)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(due: true),
                  borderRadius: BorderRadius.circular(15),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Jatuh tempo',
                      suffixIcon: _dueDate == null
                          ? const Icon(Icons.event_available_outlined)
                          : IconButton(
                              onPressed: () => setState(() => _dueDate = null),
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                    child: Text(
                      _dueDate == null ? 'Opsional' : formatDate(_dueDate!),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Tambahkan konteks atau janji pembayaran',
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
                backgroundColor: _kind == DebtKind.payable ? semanticError : semanticMint,
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
                widget.entry == null ? 'Simpan catatan' : 'Simpan perubahan',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
