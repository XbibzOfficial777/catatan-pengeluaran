import 'package:flutter/material.dart';

class AppSettingsSheet extends StatefulWidget {
  const AppSettingsSheet({
    super.key,
    required this.languageCode,
    required this.cacheInfo,
    required this.onLanguageChanged,
    required this.onBackup,
    this.onBackupToDrive,
    required this.onRestore,
    required this.onCheckUpdate,
    required this.onClearCache,
    required this.selectedTheme,
    required this.onThemeSelected,
  });

  final String languageCode;
  final String cacheInfo;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onBackup;
  final VoidCallback? onBackupToDrive;
  final VoidCallback onRestore;
  final Future<void> Function() onCheckUpdate;
  final Future<void> Function() onClearCache;
  final ThemeMode selectedTheme;
  final ValueChanged<ThemeMode> onThemeSelected;

  @override
  State<AppSettingsSheet> createState() => _AppSettingsSheetState();
}

class _AppSettingsSheetState extends State<AppSettingsSheet> {
  late String _languageCode;
  bool _checkingUpdate = false;
  bool _clearingCache = false;

  bool get _english => _languageCode == 'en';
  String t(String id, String en) => _english ? en : id;

  @override
  void initState() {
    super.initState();
    _languageCode = widget.languageCode;
  }

  Future<void> _checkUpdate() async {
    setState(() => _checkingUpdate = true);
    try {
      await widget.onCheckUpdate();
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Future<void> _clearCache() async {
    setState(() => _clearingCache = true);
    try {
      await widget.onClearCache();
    } finally {
      if (mounted) setState(() => _clearingCache = false);
    }
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
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
              Text(
                t('Pengaturan', 'Settings'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                t('Semua pengaturan aplikasi ada di satu tempat.', 'All app settings in one place.'),
                style: TextStyle(color: colors.onSurface.withValues(alpha: 0.62)),
              ),
              const SizedBox(height: 20),
              _SectionTitle(title: t('Bahasa', 'Language')),
              DropdownButtonFormField<String>(
                value: _languageCode,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.translate_rounded),
                  labelText: t('Bahasa aplikasi', 'App language'),
                ),
                items: const [
                  DropdownMenuItem(value: 'id', child: Text('Bahasa Indonesia')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _languageCode = value);
                  widget.onLanguageChanged(value);
                },
              ),
              const SizedBox(height: 20),
              _SectionTitle(title: t('Tampilan', 'Appearance')),
              DropdownButtonFormField<ThemeMode>(
                value: widget.selectedTheme,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.palette_outlined),
                  labelText: t('Tema aplikasi', 'App theme'),
                ),
                items: [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text(t('Ikuti sistem', 'System default')),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text(t('Terang', 'Light')),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text(t('Gelap', 'Dark')),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) widget.onThemeSelected(value);
                },
              ),
              const SizedBox(height: 20),
              _SectionTitle(title: t('Data dan laporan', 'Data and reports')),
              _SettingsAction(
                icon: Icons.backup_outlined,
                title: t('Backup data', 'Back up data'),
                subtitle: t('Simpan file .bibzcup yang aman.', 'Save a protected .bibzcup file.'),
                onTap: widget.onBackup,
              ),
              if (widget.onBackupToDrive != null)
                _SettingsAction(
                  icon: Icons.cloud_upload_outlined,
                  title: t('Backup ke Google Drive', 'Back up to Google Drive'),
                  subtitle: t(
                    'Bagikan arsip .bibzcup melalui menu berbagi.',
                    'Share the .bibzcup archive via the share sheet.',
                  ),
                  onTap: widget.onBackupToDrive,
                ),
              _SettingsAction(
                icon: Icons.restore_rounded,
                title: t('Restore data', 'Restore data'),
                subtitle: t('Pulihkan hanya backup .bibzcup yang valid.', 'Restore only valid .bibzcup backups.'),
                onTap: widget.onRestore,
              ),
              const SizedBox(height: 20),
              _SectionTitle(title: t('Pembaruan aplikasi', 'App updates')),
              _SettingsAction(
                icon: Icons.system_update_alt_rounded,
                title: t('Cek pembaruan', 'Check for updates'),
                subtitle: _checkingUpdate
                    ? t('Sedang memeriksa version-latest.json...', 'Checking version-latest.json...')
                    : t('Cek versi terbaru dari GitHub.', 'Check the latest version from GitHub.'),
                trailing: _checkingUpdate
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
                onTap: _checkingUpdate ? null : _checkUpdate,
              ),
              const SizedBox(height: 20),
              _SectionTitle(title: t('Penyimpanan', 'Storage')),
              _SettingsAction(
                icon: Icons.cleaning_services_outlined,
                title: t('Hapus cache', 'Clear cache'),
                subtitle: '${t('Cache aplikasi', 'App cache')}: ${widget.cacheInfo}',
                trailing: _clearingCache
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
                onTap: _clearingCache ? null : _clearCache,
              ),
              const SizedBox(height: 8),
              Text(
                t(
                  'Cache hanya berisi data sementara seperti gambar dashboard dan paket update yang belum dipasang.',
                  'Cache contains temporary data such as dashboard images and pending update packages.',
                ),
                style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.56)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w900,
        fontSize: 13,
      ),
    ),
  );
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
    ),
  );
}
