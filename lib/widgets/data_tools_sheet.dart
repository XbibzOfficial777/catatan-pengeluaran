import 'package:flutter/material.dart';

class DataToolsSheet extends StatelessWidget {
  const DataToolsSheet({
    super.key,
    required this.onBackup,
    required this.onDrive,
    required this.onRestore,
    required this.onSpreadsheet,
  });

  final VoidCallback onBackup;
  final VoidCallback onDrive;
  final VoidCallback onRestore;
  final VoidCallback onSpreadsheet;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data & laporan',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelola backup dan ekspor tanpa memenuhi layar.',
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.62),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.primary,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ActionTile(
              icon: Icons.phone_android_rounded,
              color: colors.primary,
              title: 'Backup ke perangkat',
              subtitle: 'Simpan .bibzcup ke folder CatatBibz',
              onTap: onBackup,
            ),
            _ActionTile(
              icon: Icons.drive_file_move_outline,
              color: const Color(0xFF2E7D5B),
              title: 'Backup ke Google Drive',
              subtitle: 'Gunakan menu berbagi yang aman',
              onTap: onDrive,
            ),
            _ActionTile(
              icon: Icons.restore_rounded,
              color: const Color(0xFFB86E21),
              title: 'Restore backup',
              subtitle: 'Pulihkan hanya file .bibzcup valid',
              onTap: onRestore,
            ),
            _ActionTile(
              icon: Icons.table_view_rounded,
              color: const Color(0xFF356AA5),
              title: 'Share spreadsheet Excel',
              subtitle: 'Laporan profesional siap dibagikan',
              onTap: onSpreadsheet,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.58),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: colors.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}
