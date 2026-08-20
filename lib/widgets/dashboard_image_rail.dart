import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DashboardImageRail extends StatefulWidget {
  const DashboardImageRail({
    super.key,
    required this.urls,
    required this.isLoading,
    required this.fromCache,
    required this.onRefresh,
  });

  final List<String> urls;
  final bool isLoading;
  final bool fromCache;
  final Future<void> Function() onRefresh;

  @override
  State<DashboardImageRail> createState() => _DashboardImageRailState();
}

class _DashboardImageRailState extends State<DashboardImageRail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final PageController _pageController;
  int _page = 0;
  Timer? _autoAdvance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pageController = PageController(viewportFraction: 0.86);
    _startAutoAdvance();
  }

  @override
  void didUpdateWidget(covariant DashboardImageRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.urls != oldWidget.urls) {
      if (_page >= widget.urls.length) {
        _page = 0;
        if (_pageController.hasClients) _pageController.jumpToPage(0);
      }
      _startAutoAdvance();
    }
  }

  void _startAutoAdvance() {
    _autoAdvance?.cancel();
    if (widget.urls.length < 2) return;
    _autoAdvance = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients || widget.urls.isEmpty)
        return;
      final next = (_page + 1) % widget.urls.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.fromCache ? 'Inspirasi tersimpan' : 'Inspirasi hari ini',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface.withValues(alpha: 0.66),
                  letterSpacing: 0.2,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Muat ulang gambar',
              onPressed: widget.isLoading ? null : widget.onRefresh,
              icon: widget.isLoading
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.isLoading && widget.urls.isEmpty)
          _LoadingRail(colors: colors)
        else if (widget.urls.isEmpty)
          _EmptyRail(colors: colors, onRefresh: widget.onRefresh)
        else
          SizedBox(
            height: 132,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.urls.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) => AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Transform.translate(
                  offset: Offset(
                    0,
                    index == _page ? -2 * _controller.value : 0,
                  ),
                  child: child,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _ImageTile(url: widget.urls[index], colors: colors),
                ),
              ),
            ),
          ),
        if (widget.urls.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.urls.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: index == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: index == _page ? colors.primary : colors.outline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ImageTile extends StatefulWidget {
  const _ImageTile({required this.url, required this.colors});
  final String url;
  final ColorScheme colors;

  @override
  State<_ImageTile> createState() => _ImageTileState();
}

class _ImageTileState extends State<_ImageTile> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return _ImageFallback(
        colors: widget.colors,
        onRetry: () => setState(() => _failed = false),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: CachedNetworkImage(
        imageUrl: widget.url,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 260),
        fadeOutDuration: const Duration(milliseconds: 120),
        maxWidthDiskCache: 900,
        maxHeightDiskCache: 420,
        placeholder: (_, __) => _ImageShimmer(colors: widget.colors),
        errorWidget: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _failed = true);
          });
          return _ImageFallback(
            colors: widget.colors,
            onRetry: () => setState(() => _failed = false),
          );
        },
      ),
    );
  }
}

class _ImageShimmer extends StatefulWidget {
  const _ImageShimmer({required this.colors});
  final ColorScheme colors;
  @override
  State<_ImageShimmer> createState() => _ImageShimmerState();
}

class _ImageShimmerState extends State<_ImageShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, __) => Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment(-1 + _controller.value * 2, 0),
          end: Alignment(1 + _controller.value * 2, 0),
          colors: [
            widget.colors.surfaceContainerHighest.withValues(alpha: 0.5),
            widget.colors.surfaceContainerHighest,
            widget.colors.surfaceContainerHighest.withValues(alpha: 0.5),
          ],
        ),
      ),
    ),
  );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.colors, required this.onRetry});
  final ColorScheme colors;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
    ),
    child: Center(
      child: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Coba lagi'),
      ),
    ),
  );
}

class _LoadingRail extends StatelessWidget {
  const _LoadingRail({required this.colors});
  final ColorScheme colors;
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 132, child: _ImageShimmer(colors: colors));
}

class _EmptyRail extends StatelessWidget {
  const _EmptyRail({required this.colors, required this.onRefresh});
  final ColorScheme colors;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) => Container(
    height: 92,
    decoration: BoxDecoration(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Center(
      child: TextButton.icon(
        onPressed: onRefresh,
        icon: const Icon(Icons.cloud_off_rounded, size: 18),
        label: const Text('Gambar belum tersedia'),
      ),
    ),
  );
}
