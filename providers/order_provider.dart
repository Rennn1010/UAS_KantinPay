import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  OrderModel? _currentOrder;
  List<OrderModel> _orderHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<OrderModel>? _orderSubscription;

  OrderModel? get currentOrder => _currentOrder;
  List<OrderModel> get orderHistory => _orderHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Dipakai di order_tracking_screen.dart — realtime, update otomatis
  /// begitu penjual mengubah status pesanan.
  void trackOrder(String orderId) {
    _orderSubscription?.cancel();
    _setLoading(true);
    _orderSubscription = _orderService.watchOrderById(orderId).listen(
      (order) {
        _currentOrder = order;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Gagal memuat status pesanan: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void stopTracking() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
  }

  /// Dipakai di order_history_screen.dart
  Future<void> loadOrderHistory(String buyerId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _orderHistory = await _orderService.getOrdersByBuyer(buyerId);
    } catch (e) {
      _errorMessage = 'Gagal memuat riwayat pesanan: $e';
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }
}
