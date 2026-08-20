import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/advanced_finance_service.dart';

class AnalyticsSheet extends StatelessWidget {
  const AnalyticsSheet({
    super.key,
    required this.expenses,
    required this.budgets,
    required this.insights,
  });

  final List<ExpenseEntry> expenses;
  final List<BudgetStatus> budgets;
  final List<ExpenseInsight> insights;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final monthExpenses = expenses
        .where(
          (entry) =>
              entry.date.year == now.year && entry.date.month == now.month,
        )
        .toList();
    final totals = <ExpenseCategory, double>{};
    for (final entry in monthExpenses) {
      totals[entry.category] = (totals[entry.category] ?? 0) + entry.amount;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = monthExpenses.fold(0.0, (sum, entry) => sum + entry.amount);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
              'Analisis keuangan',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Ringkasan berdasarkan transaksi yang tersimpan.',
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.62),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            _ChartCard(
              title: 'Komposisi kategori bulan ini',
              child: monthExpenses.isEmpty
                  ? const _NoChartData()
                  : SizedBox(
                      height: 210,
                      child: Row(
                        children: [
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: 42,
                                sectionsSpace: 3,
                                sections: sorted
                                    .take(6)
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final percent = total == 0
                                          ? 0
                                          : entry.value.value / total * 100;
                                      return PieChartSectionData(
                                        value: entry.value.value,
                                        title: '${percent.round()}%',
                                        color: _chartColor(entry.key, colors),
                                        radius: 72,
                                        titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      );
                                    })
                                    .toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: sorted
                                  .take(6)
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 3,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 9,
                                            height: 9,
                                            decoration: BoxDecoration(
                                              color: _chartColor(
                                                entry.key,
                                                colors,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 7),
                                          Expanded(
                                            child: Text(
                                              _categoryLabel(entry.value.key),
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _currency(entry.value.value),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            _ChartCard(
              title: 'Tren pengeluaran 7 hari',
              child: SizedBox(
                height: 190,
                child: _DailyChart(expenses: expenses, colors: colors),
              ),
            ),
            const SizedBox(height: 12),
            _ChartCard(
              title: 'Status anggaran',
              child: budgets.isEmpty
                  ? const _NoChartData()
                  : Column(
                      children: budgets
                          .map(
                            (status) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _categoryLabel(status.limit.category),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${status.percent.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          color: status.isExceeded
                                              ? colors.error
                                              : status.isAlert
                                              ? Colors.orange
                                              : colors.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: (status.percent / 100).clamp(0, 1),
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(99),
                                    color: status.isExceeded
                                        ? colors.error
                                        : status.isAlert
                                        ? Colors.orange
                                        : colors.primary,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    status.isExceeded
                                        ? 'Melebihi ${_currency(status.remaining.abs())}'
                                        : 'Sisa ${_currency(status.remaining)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.onSurface.withValues(
                                        alpha: 0.62,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            if (insights.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ChartCard(
                title: 'Perlu diperhatikan',
                child: Column(
                  children: insights
                      .take(5)
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.warning_amber_rounded,
                            color: colors.error,
                          ),
                          title: Text(
                            item.entry.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${_currency(item.entry.amount)} • ${item.ratio.toStringAsFixed(1)}× rata-rata kategori',
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _chartColor(int index, ColorScheme colors) => [
    colors.primary,
    colors.secondary,
    Colors.teal,
    Colors.blueGrey,
    Colors.orange,
    Colors.pinkAccent,
  ][index % 6];
  String _categoryLabel(ExpenseCategory category) => switch (category) {
    ExpenseCategory.food => 'Makan',
    ExpenseCategory.transport => 'Transportasi',
    ExpenseCategory.shopping => 'Belanja',
    ExpenseCategory.bills => 'Tagihan',
    ExpenseCategory.health => 'Kesehatan',
    ExpenseCategory.entertainment => 'Hiburan',
    ExpenseCategory.other => 'Lainnya',
  };
}

class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.expenses, required this.colors});
  final List<ExpenseEntry> expenses;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final values = List<double>.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day - (6 - index));
      return expenses
          .where(
            (entry) =>
                entry.date.year == day.year &&
                entry.date.month == day.month &&
                entry.date.day == day.day,
          )
          .fold(0.0, (sum, entry) => sum + entry.amount);
    });
    final maxValue = values.fold(0.0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maxValue == 0 ? 100 : maxValue * 1.25,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final date = DateTime(
                  now.year,
                  now.month,
                  now.day - (6 - value.toInt()),
                );
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${date.day}/${date.month}',
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: values
            .asMap()
            .entries
            .map(
              (entry) => BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value,
                    width: 18,
                    borderRadius: BorderRadius.circular(4),
                    color: colors.primary,
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _NoChartData extends StatelessWidget {
  const _NoChartData();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Center(
      child: Text(
        'Belum ada data untuk dianalisis.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface
              .withValues(alpha: 0.62),
        ),
      ),
    ),
  );
}

String _currency(double value) =>
    'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (_) => '.')}';
