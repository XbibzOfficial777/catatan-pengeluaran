import 'package:flutter/material.dart';

class DataToolsSheet extends StatelessWidget {
  const DataToolsSheet({
    super.key,
    required this.onBackup,
    required this.onDrive,
    required this.onRestore,
    required this.onSpreadsheet,
    required this.onPdf,
    required this.onBudgets,
    required this.onAccounts,
    required this.onRecurring,
    required this.onAnalytics,
    required this.onPrivacy,
    required this.privacyEnabled,
  });

  final VoidCallback onBackup;
  final VoidCallback onDrive;
  final VoidCallback onRestore;
  final VoidCallback onSpreadsheet;
  final VoidCallback onPdf;
  final VoidCallback onBudgets;
  final VoidCallback onAccounts;
  final VoidCallback onRecurring;
  final VoidCallback onAnalytics;
  final VoidCallback onPrivacy;
  final bool privacyEnabled;

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
              icon: Icons.analytics_outlined,
              color: colors.primary,
              title: 'Analisis keuangan',
              subtitle: 'Grafik kategori, tren, dan anomali',
              onTap: onAnalytics,
            ),
            _ActionTile(
              icon: Icons.account_balance_wallet_outlined,
              color: colors.primary,
              title: 'Akun dan dompet',
              subtitle: 'Tunai, bank, kartu, dan e-wallet',
              onTap: onAccounts,
            ),
            _ActionTile(
              icon: Icons.pie_chart_outline_rounded,
              color: const Color(0xFFB86E21),
              title: 'Anggaran bulanan',
              subtitle: 'Batas kategori dan peringatan',
              onTap: onBudgets,
            ),
            _ActionTile(
              icon: Icons.autorenew_rounded,
              color: const Color(0xFF2E7D5B),
              title: 'Transaksi berulang',
              subtitle: 'Tagihan nyata saat jatuh tempo',
              onTap: onRecurring,
            ),
            _ActionTile(
              icon: Icons.picture_as_pdf_outlined,
              color: const Color(0xFFB34242),
              title: 'Bagikan laporan PDF',
              subtitle: 'Laporan profesional bulan berjalan',
              onTap: onPdf,
            ),
            _ActionTile(
              icon: privacyEnabled
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: const Color(0xFF5E5A9A),
              title: privacyEnabled
                  ? 'Tampilkan nominal'
                  : 'Sembunyikan nominal',
              subtitle: 'Mode privasi dashboard',
              onTap: onPrivacy,
            ),
            const Divider(height: 18),
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
