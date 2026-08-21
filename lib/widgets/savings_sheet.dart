import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/advanced_finance_models.dart';
import '../core/format.dart';
import '../services/image_attachment_service.dart';

class SavingsSettingsSheet extends StatefulWidget {
  const SavingsSettingsSheet({
    super.key,
    required this.initialGoals,
    required this.imageService,
    this.onGoalsChanged,
  });

  final List<SavingsGoal> initialGoals;
  final ImageAttachmentService imageService;
  final ValueChanged<List<SavingsGoal>>? onGoalsChanged;

  @override
  State<SavingsSettingsSheet> createState() => _SavingsSettingsSheetState();
}

class _SavingsSettingsSheetState extends State<SavingsSettingsSheet> {
  late List<SavingsGoal> _goals;

  @override
  void initState() {
    super.initState();
    _goals = [...widget.initialGoals];
  }

  Future<void> _edit({SavingsGoal? goal}) async {
    final result = await showDialog<SavingsGoal>(
      context: context,
      builder: (_) => SavingsGoalEditorDialog(
        goal: goal,
        imageService: widget.imageService,
      ),
    );
    if (result == null || !mounted) return;
    if (goal?.photoPath != null && goal!.photoPath != result.photoPath) {
      await widget.imageService.delete(goal.photoPath);
      if (!mounted) return;
    }
    if (!mounted) return;
    setState(() {
      final index = _goals.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        _goals.add(result);
      } else {
        _goals[index] = result;
      }
    });
    widget.onGoalsChanged?.call(List<SavingsGoal>.unmodifiable(_goals));
  }

  Future<void> _delete(SavingsGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus tabungan ${goal.name}?'),
        content: const Text(
          'Tujuan tabungan dan foto tujuannya akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.imageService.delete(goal.photoPath);
    if (!mounted) return;
    setState(() => _goals.removeWhere((item) => item.id == goal.id));
    widget.onGoalsChanged?.call(List<SavingsGoal>.unmodifiable(_goals));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tabungan',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => _edit(),
                    tooltip: 'Tambah tabungan',
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              Text(
                'Buat tujuan, pasang foto impian, dan dapatkan pengingat menabung.',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 16),
              if (_goals.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          color: colors.primary,
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Belum ada tujuan tabungan. Tambahkan tujuan pertamamu.',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._goals.map(
                  (goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SavingsGoalCard(
                      goal: goal,
                      onEdit: () => _edit(goal: goal),
                      onDelete: () => _delete(goal),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, _goals),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Simpan tabungan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingsGoalCard extends StatelessWidget {
  const _SavingsGoalCard({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  final SavingsGoal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GoalPhoto(path: goal.photoPath, size: 66),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') onEdit();
                          if (value == 'delete') onDelete();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit tabungan'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Hapus tabungan'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '${formatCurrency(goal.savedAmount)} dari ${formatCurrency(goal.targetAmount)}',
                    style: TextStyle(
                      color: goal.isComplete
                          ? Colors.green
                          : colors.onSurface.withValues(alpha: 0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(99),
                    color: goal.isComplete ? Colors.green : colors.primary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    goal.isComplete
                        ? 'Target tercapai'
                        : '${(goal.progress * 100).toStringAsFixed(0)}% tercapai${goal.reminderEnabled ? ' • pengingat aktif' : ''}',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.58),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SavingsGoalEditorDialog extends StatefulWidget {
  const SavingsGoalEditorDialog({
    super.key,
    this.goal,
    required this.imageService,
  });

  final SavingsGoal? goal;
  final ImageAttachmentService imageService;

  @override
  State<SavingsGoalEditorDialog> createState() =>
      _SavingsGoalEditorDialogState();
}

class _SavingsGoalEditorDialogState extends State<SavingsGoalEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _saved;
  late String? _photoPath;
  late bool _reminderEnabled;
  late TimeOfDay _reminderTime;
  String? _error;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _name = TextEditingController(text: goal?.name ?? '');
    _target = TextEditingController(
      text: goal == null ? '' : goal.targetAmount.toStringAsFixed(0),
    );
    _saved = TextEditingController(
      text: goal == null ? '0' : goal.savedAmount.toStringAsFixed(0),
    );
    _photoPath = goal?.photoPath;
    _reminderEnabled = goal?.reminderEnabled ?? false;
    _reminderTime = TimeOfDay(
      hour: goal?.reminderHour ?? 20,
      minute: goal?.reminderMinute ?? 0,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _saved.dispose();
    super.dispose();
  }

  double _amount(String value) =>
      double.tryParse(value.replaceAll('.', '').replaceAll(',', '.')) ?? 0;

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil foto'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final path = await widget.imageService.pickAndStore(source: source);
    if (path != null && mounted) setState(() => _photoPath = path);
  }

  Future<void> _pickReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (time != null && mounted) setState(() => _reminderTime = time);
  }

  void _save() {
    final name = _name.text.trim();
    final target = _amount(_target.text);
    final saved = _amount(_saved.text);
    if (name.isEmpty || target <= 0 || saved < 0) {
      setState(() => _error = 'Isi nama, target, dan nominal yang valid.');
      return;
    }
    final old = widget.goal;
    Navigator.pop(
      context,
      SavingsGoal(
        id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        targetAmount: target,
        savedAmount: saved,
        photoPath: _photoPath,
        reminderEnabled: _reminderEnabled,
        reminderHour: _reminderTime.hour,
        reminderMinute: _reminderTime.minute,
        createdAt: old?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.goal == null ? 'Tambah tabungan' : 'Edit tabungan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nama tujuan tabungan',
                hintText: 'Contoh: Laptop baru atau liburan',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Target tabungan',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _saved,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Sudah terkumpul',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _GoalPhoto(path: _photoPath, size: 54),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      _photoPath == null
                          ? 'Tambah foto tujuan'
                          : 'Ganti foto tujuan',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _reminderEnabled,
              onChanged: (value) => setState(() => _reminderEnabled = value),
              title: const Text('Pengingat waktu menabung'),
              subtitle: Text(
                'Setiap hari pukul ${_reminderTime.format(context)}',
              ),
            ),
            if (_reminderEnabled)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickReminderTime,
                  icon: const Icon(Icons.schedule_rounded),
                  label: const Text('Ubah waktu pengingat'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}

class _GoalPhoto extends StatelessWidget {
  const _GoalPhoto({required this.path, required this.size});

  final String? path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final file = path == null ? null : File(path!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        child: file != null && file.existsSync()
            ? Image.file(
                file,
                fit: BoxFit.cover,
                cacheWidth: (size * 3).round(),
                cacheHeight: (size * 3).round(),
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.broken_image_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : Icon(
                Icons.savings_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
      ),
    );
  }
}
