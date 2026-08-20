import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/advanced_finance_models.dart';
import '../models/finance_models.dart';
import 'advanced_finance_service.dart';

class ReportService {
  Future<void> sharePdf({
    required List<ExpenseEntry> expenses,
    required List<DebtEntry> debts,
    required List<MoneyAccount> accounts,
    required List<BudgetLimit> budgets,
    required List<ExpenseInsight> insights,
    required double pocketMoney,
  }) async {
    final now = DateTime.now();
    final monthExpenses =
        expenses
            .where(
              (entry) =>
                  entry.date.year == now.year && entry.date.month == now.month,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final total = monthExpenses.fold(0.0, (sum, entry) => sum + entry.amount);
    final doc = pw.Document(title: 'Laporan Catatan Pengeluaran');
    final orange = PdfColor.fromHex('#F54E00');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Catatan Pengeluaran',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: orange,
              ),
            ),
            pw.Text(
              '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 18),
          pw.Text(
            'Laporan keuangan bulan ${now.month}/${now.year}',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 14),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _summaryBox('Pengeluaran bulan ini', _currency(total), orange),
              _summaryBox(
                'Uang Saku',
                _currency(pocketMoney),
                PdfColors.blueGrey,
              ),
              _summaryBox(
                'Transaksi',
                '${monthExpenses.length}',
                PdfColors.teal,
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Anggaran kategori',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (budgets.isEmpty)
            pw.Text(
              'Belum ada anggaran yang ditetapkan.',
              style: const pw.TextStyle(fontSize: 10),
            )
          else
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: orange),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: const ['Kategori', 'Batas', 'Terpakai', 'Sisa'],
              data: budgets.map((budget) {
                final spent = monthExpenses
                    .where((entry) => entry.category == budget.category)
                    .fold(0.0, (sum, entry) => sum + entry.amount);
                return [
                  _categoryName(budget.category),
                  _currency(budget.monthlyLimit),
                  _currency(spent),
                  _currency(budget.monthlyLimit - spent),
                ];
              }).toList(),
            ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Akun dan dompet',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (accounts.isEmpty)
            pw.Text('Belum ada akun.', style: const pw.TextStyle(fontSize: 10))
          else
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: PdfColors.teal),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: const ['Nama', 'Tipe', 'Saldo'],
              data: accounts
                  .where((item) => !item.isArchived)
                  .map(
                    (item) => [
                      item.name,
                      item.type.name,
                      _currency(item.balance),
                    ],
                  )
                  .toList(),
            ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Transaksi pengeluaran',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (monthExpenses.isEmpty)
            pw.Text(
              'Belum ada transaksi bulan ini.',
              style: const pw.TextStyle(fontSize: 10),
            )
          else
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headers: const ['Tanggal', 'Judul', 'Kategori', 'Nominal'],
              data: monthExpenses
                  .map(
                    (entry) => [
                      '${entry.date.day}/${entry.date.month}',
                      entry.title,
                      _categoryName(entry.category),
                      _currency(entry.amount),
                    ],
                  )
                  .toList(),
            ),
          if (debts.any((item) => !item.isSettled)) ...[
            pw.SizedBox(height: 22),
            pw.Text(
              'Hutang/piutang belum selesai',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: PdfColors.deepOrange),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headers: const ['Orang', 'Jenis', 'Nominal', 'Jatuh tempo'],
              data: debts
                  .where((item) => !item.isSettled)
                  .map(
                    (item) => [
                      item.person,
                      item.kind == DebtKind.payable
                          ? 'Saya berhutang'
                          : 'Dipinjam orang',
                      _currency(item.amount),
                      item.dueDate == null
                          ? '-'
                          : '${item.dueDate!.day}/${item.dueDate!.month}/${item.dueDate!.year}',
                    ],
                  )
                  .toList(),
            ),
          ],
          if (insights.isNotEmpty) ...[
            pw.SizedBox(height: 22),
            pw.Text(
              'Pengeluaran yang perlu diperhatikan',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            ...insights
                .take(8)
                .map(
                  (item) => pw.Bullet(
                    text:
                        '${item.entry.title}: ${_currency(item.entry.amount)} (${item.ratio.toStringAsFixed(1)}× rata-rata kategori)',
                  ),
                ),
          ],
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          'catatan-pengeluaran-${now.year}-${now.month.toString().padLeft(2, '0')}.pdf',
    );
  }

  pw.Widget _summaryBox(String title, String value, PdfColor color) =>
      pw.Container(
        width: 160,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  String _currency(double value) =>
      'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (_) => '.')}';
  String _categoryName(ExpenseCategory category) => switch (category) {
    ExpenseCategory.food => 'Makan',
    ExpenseCategory.transport => 'Transportasi',
    ExpenseCategory.shopping => 'Belanja',
    ExpenseCategory.bills => 'Tagihan',
    ExpenseCategory.health => 'Kesehatan',
    ExpenseCategory.entertainment => 'Hiburan',
    ExpenseCategory.other => 'Lainnya',
  };
}
