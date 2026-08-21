import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../models/finance_models.dart';
import '../services/image_attachment_service.dart';

Future<bool> confirmDeleteEntry(BuildContext context, Object entry) async {
  final label = entry is ExpenseEntry
      ? entry.title
      : entry is DebtEntry
      ? entry.person
      : 'catatan ini';
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus catatan?'),
      content: Text(
        'Catatan "$label" akan dihapus. Tindakan ini tidak bisa dibatalkan dari daftar utama.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> pickEditStoreImage(
  BuildContext context,
  ImageAttachmentService service,
  ImageSource source,
) async {
  final pickedPath = await service.pickAndStore(source: source);
  if (pickedPath == null) return null;
  final bytes = await File(pickedPath).readAsBytes();
  if (!context.mounted) return pickedPath;
  final edited = await Navigator.push<Uint8List>(
    context,
    MaterialPageRoute(builder: (_) => ImageEditor(image: bytes)),
  );
  if (edited == null) return pickedPath;
  final editedPath = await service.storeBytes(edited);
  await service.delete(pickedPath);
  return editedPath;
}
