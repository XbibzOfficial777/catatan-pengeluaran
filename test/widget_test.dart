import 'package:flutter_test/flutter_test.dart';

import 'package:catatan_pengeluaran/main.dart';

void main() {
  testWidgets('Catatan Pengeluaran renders the app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const CatatanPengeluaranApp());
    await tester.pump();

    expect(find.text('Catatan Pengeluaran'), findsOneWidget);
  });
}
