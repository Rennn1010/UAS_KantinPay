import 'package:flutter/foundation.dart';
import '../models/seller_qris_model.dart';
import '../services/seller_qris_service.dart';

class SellerQrisProvider extends ChangeNotifier {
  final SellerQrisService _service = SellerQrisService();

  SellerQrisModel? _qris;
  bool _isLoading = false;
  String? _errorMessage;

  SellerQrisModel? get qris => _qris;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasQris => _qris != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadQris(String sellerId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _qris = await _service.getSellerQris(sellerId);
    } catch (e) {
      _errorMessage = 'Gagal memuat QRIS: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> uploadQris({
    required String sellerId,
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _qris = await _service.uploadQrisImage(
        sellerId: sellerId,
        imageBytes: imageBytes,
        imageName: imageName,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Gagal upload QRIS: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
