import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';

/// Service ini menangani semua operasi database terkait pembayaran.
/// Alur QRIS dummy:
///  1. createPayment()      -> dipanggil saat checkout, status = pending
///  2. buyerConfirmPayment()-> pembeli klik "Sudah Bayar", status = waiting_verification
///  3. sellerVerifyPayment()-> penjual klik "Verifikasi Pembayaran", status = paid
class PaymentService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Ambil URL QRIS aktif milik penjual (dipakai saat checkout QRIS)
  Future<String?> getActiveSellerQrisUrl(String sellerId) async {
    final response =
        await _client
            .from('seller_qris')
            .select('qris_image_url')
            .eq('seller_id', sellerId)
            .eq('is_active', true)
            .maybeSingle();

    if (response == null) return null;
    return response['qris_image_url'] as String?;
  }

  /// Dipanggil saat order berhasil dibuat (checkout)
  Future<PaymentModel> createPayment({
    required String orderId,
    required PaymentMethod method,
    String? qrisImageUrl,
  }) async {
    // COD tidak melalui alur verifikasi pembayaran (bayar saat ambil),
    // jadi payment langsung dianggap "paid" begitu dipilih.
    final initialStatus =
        method == PaymentMethod.cod
            ? PaymentStatus.paid
            : PaymentStatus.pending;

    final payload = {
      'order_id': orderId,
      'method': method.value,
      'status': initialStatus.value,
      if (qrisImageUrl != null) 'qris_image_url': qrisImageUrl,
    };

    final response =
        await _client
            .from('payments')
            .upsert(payload, onConflict: 'order_id')
            .select()
            .single();

    final payment = PaymentModel.fromMap(response);

    // Untuk COD, order lanjut ke "diproses" karena tidak ada pembayaran
    // yang perlu diverifikasi. Naik bertahap (bukan lompat langsung dari
    // menunggu_pembayaran -> diproses) supaya konsisten dengan urutan
    // transisi yang sama seperti alur QRIS.
    if (method == PaymentMethod.cod) {
      await _client
          .from('orders')
          .update({'status': 'menunggu_verifikasi'})
          .eq('id', orderId);
      await _client
          .from('orders')
          .update({'status': 'diproses'})
          .eq('id', orderId);
    }

    return payment;
  }

  /// Ambil data pembayaran berdasarkan order_id
  Future<PaymentModel?> getPaymentByOrderId(String orderId) async {
    final response =
        await _client
            .from('payments')
            .select()
            .eq('order_id', orderId)
            .maybeSingle();

    if (response == null) return null;
    return PaymentModel.fromMap(response);
  }

  /// Tombol "Sudah Bayar" oleh pembeli
  Future<PaymentModel> buyerConfirmPayment(String paymentId) async {
    final response =
        await _client
            .from('payments')
            .update({
              'status': PaymentStatus.waitingVerification.value,
              'confirmed_by_buyer_at': DateTime.now().toIso8601String(),
            })
            .eq('id', paymentId)
            .select()
            .single();

    // Update status order menjadi "menunggu_verifikasi"
    final payment = PaymentModel.fromMap(response);
    await _client
        .from('orders')
        .update({'status': 'menunggu_verifikasi'})
        .eq('id', payment.orderId);

    return payment;
  }

  /// Tombol "Verifikasi Pembayaran" oleh penjual
  Future<PaymentModel> sellerVerifyPayment(String paymentId) async {
    final response =
        await _client
            .from('payments')
            .update({
              'status': PaymentStatus.paid.value,
              'verified_by_seller_at': DateTime.now().toIso8601String(),
            })
            .eq('id', paymentId)
            .select()
            .single();

    // Update status order menjadi "diproses" setelah pembayaran terverifikasi
    final payment = PaymentModel.fromMap(response);
    await _client
        .from('orders')
        .update({'status': 'diproses'})
        .eq('id', payment.orderId);

    return payment;
  }

  /// Untuk COD, tandai lunas otomatis saat pesanan diambil/selesai
  Future<PaymentModel> markCodAsPaid(String paymentId) async {
    final response =
        await _client
            .from('payments')
            .update({'status': PaymentStatus.paid.value})
            .eq('id', paymentId)
            .select()
            .single();

    return PaymentModel.fromMap(response);
  }

  /// Realtime stream untuk memantau perubahan status pembayaran
  /// Berguna di order_tracking_screen.dart (pembeli) dan order_detail_screen.dart (penjual)
  Stream<PaymentModel?> watchPaymentByOrderId(String orderId) {
    return _client
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .map((rows) => rows.isEmpty ? null : PaymentModel.fromMap(rows.first));
  }
}
