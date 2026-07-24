import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  PaymentModel? _payment;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<PaymentModel?>? _paymentSubscription;

  PaymentModel? get payment => _payment;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isPending => _payment?.status == PaymentStatus.pending;
  bool get isWaitingVerification =>
      _payment?.status == PaymentStatus.waitingVerification;
  bool get isPaid => _payment?.status == PaymentStatus.paid;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Ambil URL QRIS aktif milik penjual (dipanggil di payment_screen.dart)
  Future<String?> fetchSellerQrisUrl(String sellerId) async {
    try {
      return await _paymentService.getActiveSellerQrisUrl(sellerId);
    } catch (e) {
      _setError('Gagal mengambil QRIS penjual: $e');
      return null;
    }
  }

  /// Dipanggil setelah order berhasil dibuat saat checkout
  Future<bool> createPayment({
    required String orderId,
    required PaymentMethod method,
    String? qrisImageUrl,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      _payment = await _paymentService.createPayment(
        orderId: orderId,
        method: method,
        qrisImageUrl: qrisImageUrl,
      );
      return true;
    } catch (e) {
      _setError('Gagal membuat pembayaran: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Muat data pembayaran berdasarkan order (dipanggil di tracking/detail screen)
  Future<void> loadPaymentByOrderId(String orderId) async {
    _setLoading(true);
    _setError(null);
    try {
      _payment = await _paymentService.getPaymentByOrderId(orderId);
    } catch (e) {
      _setError('Gagal memuat data pembayaran: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Dipanggil dari tombol "Sudah Bayar" di sisi pembeli
  Future<bool> confirmPaymentByBuyer() async {
    if (_payment == null) return false;
    _setLoading(true);
    _setError(null);
    try {
      _payment = await _paymentService.buyerConfirmPayment(_payment!.id);
      return true;
    } catch (e) {
      _setError('Gagal konfirmasi pembayaran: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Dipanggil dari tombol "Verifikasi Pembayaran" di sisi penjual
  Future<bool> verifyPaymentBySeller() async {
    if (_payment == null) return false;
    _setLoading(true);
    _setError(null);
    try {
      _payment = await _paymentService.sellerVerifyPayment(_payment!.id);
      return true;
    } catch (e) {
      _setError('Gagal verifikasi pembayaran: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Tandai pembayaran COD lunas (misalnya saat pesanan diambil)
  Future<bool> markCodAsPaid() async {
    if (_payment == null) return false;
    _setLoading(true);
    _setError(null);
    try {
      _payment = await _paymentService.markCodAsPaid(_payment!.id);
      return true;
    } catch (e) {
      _setError('Gagal update pembayaran COD: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Mulai dengarkan perubahan status pembayaran secara realtime
  void listenToPayment(String orderId) {
    _paymentSubscription?.cancel();
    _paymentSubscription =
        _paymentService.watchPaymentByOrderId(orderId).listen((updated) {
      _payment = updated;
      notifyListeners();
    });
  }

  void stopListening() {
    _paymentSubscription?.cancel();
    _paymentSubscription = null;
  }

  @override
  void dispose() {
    _paymentSubscription?.cancel();
    super.dispose();
  }
}
