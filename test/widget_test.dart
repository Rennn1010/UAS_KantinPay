// Test dasar bawaan Flutter, sudah disesuaikan agar mengetes KantinPayApp
// (bukan MyApp template default) supaya tidak error saat dijalankan.
//
// Catatan: karena KantinPayApp membutuhkan Supabase yang sudah diinisialisasi
// dan koneksi internet ke database, widget test bawaan ini sengaja dibuat
// minimal (hanya cek app bisa dibangun tanpa exception langsung).
// Untuk pengujian yang lebih dalam, sebaiknya buat test terpisah per widget
// kecil yang tidak bergantung pada Supabase.

import 'package:flutter_test/flutter_test.dart';

import 'package:kantinpay/main.dart';

void main() {
  testWidgets('KantinPayApp dapat dibangun tanpa error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KantinPayApp());

    // Cukup verifikasi tidak ada exception saat widget tree dibangun.
    // Splash screen adalah halaman pertama yang muncul.
    expect(find.byType(KantinPayApp), findsOneWidget);
  });
}
