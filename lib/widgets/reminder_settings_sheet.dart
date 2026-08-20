import 'package:flutter/material.dart';

import '../models/reminder_models.dart';

class ReminderSettingsSheet extends StatefulWidget {
  const ReminderSettingsSheet({super.key, required this.initialReminders});

  final List<ReminderSchedule> initialReminders;

  @override
  State<ReminderSettingsSheet> createState() => _ReminderSettingsSheetState();
}

class _ReminderSettingsSheetState extends State<ReminderSettingsSheet> {
  late List<ReminderSchedule> _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = [...widget.initialReminders];
  }

  Future<void> _addOrEdit({ReminderSchedule? reminder}) async {
    final result = await showDialog<ReminderSchedule>(
      context: context,
      builder: (_) => ReminderEditorDialog(reminder: reminder),
    );
    if (result == null || !mounted) return;
    setState(() {
      final index = _reminders.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        _reminders = [..._reminders, result];
      } else {
        _reminders[index] = result;
      }
    });
  }

  Future<void> _delete(ReminderSchedule reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus pengingat?'),
        content: Text('Jadwal “${reminder.title}” akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _reminders.removeWhere((item) => item.id == reminder.id));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengingat jadwal',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bayar, makan, ngopi, atau agenda lain sesuai kebiasaanmu.',
                          style: TextStyle(
                            color: colors.onSurface.withValues(alpha: 0.62),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => _addOrEdit(),
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Tambah pengingat',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_reminders.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Belum ada pengingat. Tambahkan jadwal pertama untuk mendapatkan notifikasi lokal.',
                  ),
                )
              else
                ..._reminders.asMap().entries.map((entry) {
                  final index = entry.key;
                  final reminder = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: colors.primary.withValues(
                            alpha: 0.12,
                          ),
                          child: Icon(
                            _iconFor(reminder.title),
                            color: colors.primary,
                          ),
                        ),
                        title: Text(
                          reminder.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${_timeLabel(reminder)} • ${_frequencyLabel(reminder)}\n${reminder.body}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: reminder.enabled,
                              onChanged: (value) => setState(
                                () => _reminders[index] = reminder.copyWith(
                                  enabled: value,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _addOrEdit(reminder: reminder);
                                }
                                if (value == 'delete') {
                                  _delete(reminder);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Hapus'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, _reminders),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Simpan dan aktifkan jadwal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String title) {
    final text = title.toLowerCase();
    if (text.contains('bayar') ||
        text.contains('hutang') ||
        text.contains('tagihan'))
      return Icons.payments_outlined;
    if (text.contains('makan')) return Icons.restaurant_outlined;
    if (text.contains('kopi') || text.contains('ngopi'))
      return Icons.coffee_outlined;
    return Icons.event_note_outlined;
  }

  String _timeLabel(ReminderSchedule reminder) =>
      '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}';

  String _frequencyLabel(ReminderSchedule reminder) {
    if (reminder.frequency == ReminderFrequency.daily) return 'Setiap hari';
    const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final days = reminder.weekdays.map((day) => labels[day - 1]).join(', ');
    return days.isEmpty ? 'Mingguan belum dipilih' : 'Setiap $days';
  }
}

class ReminderEditorDialog extends StatefulWidget {
  const ReminderEditorDialog({super.key, this.reminder});

  final ReminderSchedule? reminder;

  @override
  State<ReminderEditorDialog> createState() => _ReminderEditorDialogState();
}

class _ReminderEditorDialogState extends State<ReminderEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late TimeOfDay _time;
  late ReminderFrequency _frequency;
  late Set<int> _weekdays;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _title = TextEditingController(text: reminder?.title ?? 'Pengingat baru');
    _body = TextEditingController(
      text: reminder?.body ?? 'Saatnya melihat catatanmu.',
    );
    _time = TimeOfDay(hour: reminder?.hour ?? 8, minute: reminder?.minute ?? 0);
    _frequency = reminder?.frequency ?? ReminderFrequency.daily;
    _weekdays = reminder == null ? <int>{} : {...reminder.weekdays};
    if (_frequency == ReminderFrequency.weekly && _weekdays.isEmpty)
      _weekdays = {1, 2, 3, 4, 5};
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Pilih waktu pengingat',
    );
    if (selected != null && mounted) setState(() => _time = selected);
  }

  void _save() {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || body.isEmpty) return;
    if (_frequency == ReminderFrequency.weekly && _weekdays.isEmpty) return;
    final reminder =
        widget.reminder ??
        ReminderSchedule(
          id: DateTime.now().millisecondsSinceEpoch.remainder(2000000000),
          title: title,
          body: body,
          hour: _time.hour,
          minute: _time.minute,
          frequency: _frequency,
          weekdays: _weekdays.toList()..sort(),
        );
    Navigator.pop(
      context,
      reminder.copyWith(
        title: title,
        body: body,
        hour: _time.hour,
        minute: _time.minute,
        frequency: _frequency,
        weekdays: _weekdays.toList()..sort(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.reminder == null ? 'Tambah pengingat' : 'Edit pengingat',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Judul',
                hintText: 'Contoh: Bayar tagihan',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Pesan notifikasi',
                hintText: 'Contoh: Cek jadwal pembayaran hari ini.',
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_rounded),
              title: const Text('Waktu'),
              trailing: Text(
                _time.format(context),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              onTap: _pickTime,
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<ReminderFrequency>(
              value: _frequency,
              decoration: const InputDecoration(labelText: 'Frekuensi'),
              items: const [
                DropdownMenuItem(
                  value: ReminderFrequency.daily,
                  child: Text('Setiap hari'),
                ),
                DropdownMenuItem(
                  value: ReminderFrequency.weekly,
                  child: Text('Hari tertentu setiap minggu'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _frequency = value);
              },
            ),
            if (_frequency == ReminderFrequency.weekly) ...[
              const SizedBox(height: 14),
              const Text(
                'Pilih hari',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  const labels = [
                    'Sen',
                    'Sel',
                    'Rab',
                    'Kam',
                    'Jum',
                    'Sab',
                    'Min',
                  ];
                  return FilterChip(
                    label: Text(labels[index]),
                    selected: _weekdays.contains(day),
                    onSelected: (selected) => setState(() {
                      if (selected)
                        _weekdays.add(day);
                      else
                        _weekdays.remove(day);
                    }),
                  );
                }),
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
        FilledButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}
