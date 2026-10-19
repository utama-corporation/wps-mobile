// lib/features/proses_produksi/view/proses_produksi_list_screen_test.dart
//
// Regresi untuk dua bug pada ProsesProduksiListScreen:
//  1. Auto-load tidak jalan -> user harus pull-to-refresh dulu.
//  2. Pencarian tidak memfilter apa pun.
//
// Keduanya akibat `_vm = context.read<ProsesProduksiListViewModel>()` diambil
// dari context milik screen itu sendiri, sementara ChangeNotifierProvider-nya
// dibuat di dalam build() screen tersebut (provider = descendant, bukan
// ancestor) sehingga `context.read` melempar ProviderNotFoundException.
//
// Test ini tidak butuh jaringan: cukup memastikan refresh() terpanggil
// otomatis tanpa interaksi user, dan mengetik di search field tidak melempar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wps_mobile/features/proses_produksi/model/proses_produksi_process.dart';
import 'package:wps_mobile/features/proses_produksi/view/proses_produksi_list_screen.dart';

void main() {
  final s4s = prosesProduksiProcesses.firstWhere((p) => p.apiSegment == 's4s');

  Future<void> pumpScreen(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'token': 'dummy-token'});
    await tester.pumpWidget(
      MaterialApp(home: ProsesProduksiListScreen(process: s4s)),
    );
    await tester.pump();
  }

  testWidgets('auto-load jalan tanpa perlu pull-to-refresh', (tester) async {
    await pumpScreen(tester);

    // Panggilan HTTP akan gagal (tidak ada jaringan di test), tapi yang
    // penting: view model sudah terpakai tanpa interaksi user. Kalau
    // ProviderNotFoundException muncul lagi, request tidak pernah dikirim.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    // Tidak boleh masih di state "belum ada data" tanpa ada error ->
    // berarti tidak ada request yang jalan sama sekali.
    expect(find.text('Belum ada data'), findsNothing);
  });

  testWidgets('mengetik di search tidak melempar exception', (tester) async {
    await pumpScreen(tester);
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(TextField), 'RA.003404');
    // Lewati debounce 250ms.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('RA.003404'), findsOneWidget);
  });
}