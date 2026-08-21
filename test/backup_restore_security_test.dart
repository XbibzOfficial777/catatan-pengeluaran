import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';

import 'package:catatan_pengeluaran/services/backup_integrity_service.dart';
import 'package:catatan_pengeluaran/services/data_transfer_service.dart';

void main() {
  group('CrossDeviceBackupException', () {
    test('membawa path sumber dan pesan ramah pengguna', () {
      const error = CrossDeviceBackupException('/tmp/backup.bibzcup');
      expect(error.sourcePath, '/tmp/backup.bibzcup');
      expect(error.message, contains('perangkat lain'));
      expect(error.toString(), startsWith('FormatException:'));
    });
  });

  group('BackupIntegrityService.isSafeRelativePath', () {
    final service = BackupIntegrityService();
    test('path relatif normal aman', () {
      expect(service.isSafeRelativePath('photos/expense_1.jpg'), isTrue);
      expect(service.isSafeRelativePath('manifest.xml'), isTrue);
    });
    test('path absolut, traversal, dan backslash ditolak (anti zip-slip)', () {
      expect(service.isSafeRelativePath('/etc/passwd'), isFalse);
      expect(service.isSafeRelativePath('../../evil.jpg'), isFalse);
      expect(service.isSafeRelativePath('photos/../../evil.jpg'), isFalse);
      expect(service.isSafeRelativePath('photos\\evil.jpg'), isFalse);
      expect(service.isSafeRelativePath(''), isFalse);
    });
  });

  group('BackupIntegrityService.verifyArchiveFiles', () {
    final service = BackupIntegrityService();

    Archive buildArchive(Map<String, List<int>> files) {
      final archive = Archive();
      files.forEach((name, content) {
        archive.addFile(ArchiveFile(name, content.length, content));
      });
      return archive;
    }

    test('arsip utuh dengan hash cocok → true', () async {
      final content = 'foto-asli'.codeUnits;
      final archive = buildArchive({
        'photos/a.jpg': content,
      });
      final hashes = {
        'photos/a.jpg': crypto.sha256.convert(content).toString(),
      };
      expect(await service.verifyArchiveFiles(archive, hashes), isTrue);
    });

    test('konten file diubah → false (deteksi tamper/rusak)', () async {
      final hashes = {
        'photos/a.jpg': crypto.sha256.convert('asli'.codeUnits).toString(),
      };
      final archive = buildArchive({
        'photos/a.jpg': 'dimodifikasi'.codeUnits,
      });
      expect(await service.verifyArchiveFiles(archive, hashes), isFalse);
    });

    test('file tidak terdaftar di manifest → false', () async {
      final content = 'x'.codeUnits;
      final archive = buildArchive({
        'photos/a.jpg': content,
        'photos/sisipan.jpg': content,
      });
      final hashes = {
        'photos/a.jpg': crypto.sha256.convert(content).toString(),
      };
      expect(await service.verifyArchiveFiles(archive, hashes), isFalse);
    });

    test('file terdeklarasi hilang dari arsip → false', () async {
      final archive = buildArchive({'photos/a.jpg': 'x'.codeUnits});
      final hashes = {
        'photos/a.jpg': crypto.sha256.convert('x'.codeUnits).toString(),
        'photos/b.jpg': crypto.sha256.convert('y'.codeUnits).toString(),
      };
      expect(await service.verifyArchiveFiles(archive, hashes), isFalse);
    });

    test('entri path berbahaya di arsip → false', () async {
      final content = 'x'.codeUnits;
      final archive = buildArchive({
        '../evil.jpg': content,
      });
      final hashes = {
        '../evil.jpg': crypto.sha256.convert(content).toString(),
      };
      expect(await service.verifyArchiveFiles(archive, hashes), isFalse);
    });
  });
}
