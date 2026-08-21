import 'dart:io';

import 'package:flutter/material.dart';

import '../core/categories.dart';
import '../core/format.dart';
import '../core/palette.dart';
import '../models/advanced_finance_models.dart';
import '../models/finance_models.dart';
import 'entry_actions.dart';

class PageHeading extends StatelessWidget {
  const PageHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.62),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 13),
          Text(
            label,
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.62),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class DebtAmount extends StatelessWidget {
  const DebtAmount({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatCurrency(amount),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedCardEntry extends StatelessWidget {
  const AnimatedCardEntry({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class SavingsOverviewCard extends StatelessWidget {
  const SavingsOverviewCard({required this.goal, required this.onTap});

  final SavingsGoal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final file = goal.photoPath == null ? null : File(goal.photoPath!);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: file != null && file.existsSync()
                      ? Image.file(
                          file,
                          fit: BoxFit.cover,
                          cacheWidth: 180,
                          cacheHeight: 180,
                          errorBuilder: (context, error, stackTrace) =>
                              ColoredBox(
                                color: colors.primary.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: colors.primary,
                                ),
                              ),
                        )
                      : ColoredBox(
                          color: colors.primary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.savings_outlined,
                            color: colors.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: goal.progress,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${formatCurrency(goal.savedAmount)} / ${formatCurrency(goal.targetAmount)}${goal.reminderEnabled ? ' • pengingat' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    required this.entry,
    required this.onTap,
    required this.onDelete,
    this.onLongPress,
    this.onAttachmentTap,
    this.selectable = false,
    this.selected = false,
    this.onSelect,
  });
  final ExpenseEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;
  final VoidCallback? onAttachmentTap;
  final bool selectable;
  final bool selected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedCardEntry(
      child: Dismissible(
        key: ValueKey(entry.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => confirmDeleteEntry(context, entry),
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete_outline_rounded, color: colors.error),
        ),
        child: Material(
          color: selected
              ? colors.primary.withValues(alpha: 0.1)
              : colors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  if (selectable)
                    Checkbox(
                      value: selected,
                      onChanged: (_) => onSelect?.call(),
                    ),
                  CategoryIcon(category: entry.category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${categoryLabel(entry.category)} • ${formatDate(entry.date)}${entry.isSettled ? ' • Lunas' : ''}',
                          style: TextStyle(
                            color: entry.isSettled
                                ? semanticMint
                                : colors.onSurface.withValues(alpha: 0.58),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency(entry.amount),
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (entry.imagePath != null) ...[
                        const SizedBox(height: 5),
                        _AttachmentThumbnail(
                          path: entry.imagePath!,
                          onTap: onAttachmentTap,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DebtTile extends StatelessWidget {
  const DebtTile({
    required this.entry,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    required this.onCommunicate,
    this.onLongPress,
    this.onAttachmentTap,
  });
  final DebtEntry entry;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onCommunicate;
  final VoidCallback? onLongPress;
  final VoidCallback? onAttachmentTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = entry.kind == DebtKind.payable ? semanticError : semanticMint;
    return AnimatedCardEntry(
      child: Dismissible(
        key: ValueKey(entry.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => confirmDeleteEntry(context, entry),
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete_outline_rounded, color: colors.error),
        ),
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
              child: Row(
                children: [
                  Checkbox(
                    value: entry.isSettled,
                    onChanged: (_) => onToggle(),
                    activeColor: semanticMint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      entry.kind == DebtKind.payable
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: color,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.person,
                          style: TextStyle(
                            color: entry.isSettled
                                ? colors.onSurface.withValues(alpha: 0.45)
                                : colors.onSurface,
                            fontWeight: FontWeight.w800,
                            decoration: entry.isSettled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (entry.contactPhone?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            entry.contactPhone!,
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.5),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '${entry.kind == DebtKind.payable ? 'Hutang' : 'Piutang'} • ${entry.dueDate == null ? 'Tanpa tenggat' : 'Jatuh tempo ${formatDate(entry.dueDate!)}'}',
                          style: TextStyle(
                            color: colors.onSurface.withValues(alpha: 0.58),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: entry.contactPhone?.isNotEmpty == true
                        ? 'Kirim pesan'
                        : 'Pilih kontak terlebih dahulu',
                    onPressed: onCommunicate,
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 19,
                      color: entry.contactPhone?.isNotEmpty == true
                          ? colors.primary
                          : colors.onSurface.withValues(alpha: 0.28),
                    ),
                  ),
                  const SizedBox(width: 2),
                  if (entry.imagePath != null) ...[
                    _AttachmentThumbnail(
                      path: entry.imagePath!,
                      onTap: onAttachmentTap,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    formatCurrency(entry.amount),
                    style: TextStyle(
                      color: entry.isSettled
                          ? colors.onSurface.withValues(alpha: 0.45)
                          : color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  const _AttachmentThumbnail({required this.path, this.onTap});

  final String path;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final file = File(path);
    final child = ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: SizedBox(
        width: 30,
        height: 30,
        child: file.existsSync()
            ? Image.file(
                file,
                fit: BoxFit.cover,
                cacheWidth: 90,
                cacheHeight: 90,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: colors.primary.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 16,
                    color: colors.primary,
                  ),
                ),
              )
            : ColoredBox(
                color: colors.primary.withValues(alpha: 0.12),
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 16,
                  color: colors.primary,
                ),
              ),
      ),
    );
    return Semantics(
      button: onTap != null,
      label: 'Lampiran gambar',
      child: onTap == null
          ? child
          : GestureDetector(onTap: onTap, child: child),
    );
  }
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({required this.category});
  final ExpenseCategory category;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = categoryColor(category, colors);
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(categoryIcon(category), color: color, size: 21),
    );
  }
}
