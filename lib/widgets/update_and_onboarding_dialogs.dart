import 'package:flutter/material.dart';

class FirstRunOnboardingDialog extends StatefulWidget {
  const FirstRunOnboardingDialog({super.key});

  @override
  State<FirstRunOnboardingDialog> createState() =>
      _FirstRunOnboardingDialogState();
}

class _FirstRunOnboardingDialogState extends State<FirstRunOnboardingDialog> {
  final _controller = PageController();
  var _page = 0;

  static const _pages = <_OnboardingContent>[
    _OnboardingContent(
      icon: Icons.edit_note_rounded,
      title: 'Catat tanpa ribet',
      description:
          'Simpan pengeluaran, uang saku, kategori, catatan, dan foto struk dalam satu tempat yang rapi.',
    ),
    _OnboardingContent(
      icon: Icons.handshake_outlined,
      title: 'Kelola hutang dan piutang',
      description:
          'Pilih kontak, tentukan jatuh tempo, kirim pengingat, lalu gunakan menu tekan lama untuk edit, hapus, atau menandai lunas.',
    ),
    _OnboardingContent(
      icon: Icons.savings_outlined,
      title: 'Capai tujuan tabungan',
      description:
          'Buat target tabungan, pasang foto impian, dan aktifkan pengingat waktu menabung setiap hari.',
    ),
    _OnboardingContent(
      icon: Icons.backup_outlined,
      title: 'Data tetap aman',
      description:
          'Gunakan menu Setting untuk backup, restore, spreadsheet, laporan, dan update aplikasi dari GitHub Release resmi.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pages.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_page + 1}/${_pages.length}',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.58),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              height: 280,
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, size: 48, color: colors.primary),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          height: 1.45,
                          color: colors.onSurface.withValues(alpha: 0.66),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: index == _page ? 22 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == _page
                        ? colors.primary
                        : colors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                child: Text(
                  _page == _pages.length - 1
                      ? 'Mulai gunakan aplikasi'
                      : 'Lanjut',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangelogDialog extends StatelessWidget {
  const ChangelogDialog({
    super.key,
    required this.version,
    required this.content,
  });

  final String version;
  final String content;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.new_releases_outlined, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text('Pembaruan $version')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 430),
        child: SingleChildScrollView(
          child: SelectableText(
            content.trim().isEmpty
                ? 'Perbaikan dan peningkatan stabilitas aplikasi.'
                : content.trim(),
            style: const TextStyle(height: 1.45),
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Mengerti'),
        ),
      ],
    );
  }
}

class _OnboardingContent {
  const _OnboardingContent({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
