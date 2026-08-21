import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/finance_models.dart';
import 'form_scaffolding.dart';

enum CommunicationChannel { whatsapp, sms }

class CommunicationRequest {
  const CommunicationRequest({required this.channel, required this.message});

  final CommunicationChannel channel;
  final String message;
}

class CommunicationSheet extends StatefulWidget {
  const CommunicationSheet({super.key, required this.entry});
  final DebtEntry entry;

  @override
  State<CommunicationSheet> createState() => _CommunicationSheetState();
}

class _CommunicationSheetState extends State<CommunicationSheet> {
  late final TextEditingController _message;
  CommunicationChannel _channel = CommunicationChannel.whatsapp;

  @override
  void initState() {
    super.initState();
    _message = TextEditingController(text: defaultDebtMessage(widget.entry));
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _submit() {
    final message = _message.text.trim();
    if (message.isEmpty) return;
    Navigator.pop(
      context,
      CommunicationRequest(channel: _channel, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isWhatsApp = _channel == CommunicationChannel.whatsapp;
    return SheetShell(
      title: 'Kirim pengingat',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  color: colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.person,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.entry.contactPhone ?? '',
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.58),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SegmentedButton<CommunicationChannel>(
            segments: const [
              ButtonSegment(
                value: CommunicationChannel.whatsapp,
                label: Text('WhatsApp'),
                icon: Icon(Icons.chat_rounded),
              ),
              ButtonSegment(
                value: CommunicationChannel.sms,
                label: Text('SMS'),
                icon: Icon(Icons.sms_outlined),
              ),
            ],
            selected: {_channel},
            onSelectionChanged: (value) =>
                setState(() => _channel = value.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _message,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Pesan',
              alignLabelWithHint: true,
              hintText: 'Tulis pesan pengingat...',
            ),
          ),
          const SizedBox(height: 19),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: isWhatsApp
                    ? const Color(0xFF16A085)
                    : colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(isWhatsApp ? Icons.chat_rounded : Icons.sms_rounded),
              label: Text(
                isWhatsApp ? 'Buka WhatsApp' : 'Buka aplikasi SMS',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String defaultDebtMessage(DebtEntry entry) {
  final due = entry.dueDate == null
      ? ''
      : ' Jatuh tempo yang tercatat adalah ${formatDate(entry.dueDate!)}.';
  if (entry.kind == DebtKind.payable) {
    return 'Halo ${entry.person}, saya ingin mengabari tentang hutang saya sebesar ${formatCurrency(entry.amount)}.$due Terima kasih.';
  }
  return 'Halo ${entry.person}, izin mengingatkan tentang hutang sebesar ${formatCurrency(entry.amount)}.$due Mohon kabari jika sudah ada waktu pembayarannya. Terima kasih.';
}
