import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class SellerOrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<OrderModel> _orders = [];
  OrderModel? _selectedOrder;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<OrderModel>? _orderSubscription;

  List<OrderModel> get orders => _orders;
  OrderModel? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Dipakai di order_list_screen.dart, bisa difilter per status (contoh: tab "Perlu Diproses")
  Future<void> loadOrders(String sellerId, {OrderStatus? filterStatus}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _orders = await _orderService.getOrdersBySeller(
        sellerId,
        filterStatus: filterStatus,
      );
    } catch (e) {
      _errorMessage = 'Gagal memuat daftar pesanan: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Dipakai di order_detail_screen.dart — realtime agar detail auto-update
  void watchOrderDetail(String orderId) {
    _orderSubscription?.cancel();
    _setLoading(true);
    _orderSubscription = _orderService.watchOrderById(orderId).listen(
      (order) {
        _selectedOrder = order;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Gagal memuat detail pesanan: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void stopWatchingDetail() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
  }

  /// Ubah status pesanan: diproses -> siap_diambil -> selesai, atau dibatalkan
  Future<bool> updateStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengubah status pesanan: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }
}
