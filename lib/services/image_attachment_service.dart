import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageAttachmentService {
  ImageAttachmentService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickAndStore({required ImageSource source}) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 86,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked == null) return null;

    final directory = await getApplicationDocumentsDirectory();
    final extension = picked.path.contains('.')
        ? picked.path.split('.').last
        : 'jpg';
    final fileName =
        'attachment_${DateTime.now().microsecondsSinceEpoch}.$extension';
    final target = File('${directory.path}/$fileName');
    await File(picked.path).copy(target.path);
    return target.path;
  }

  Future<String> storeBytes(Uint8List bytes, {String extension = 'jpg'}) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'attachment_${DateTime.now().microsecondsSinceEpoch}.$extension';
    final target = File('${directory.path}/$fileName');
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A missing attachment should not block editing or deleting a record.
    }
  }
}
