import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();

  List<CartItemModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CartItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _items.isEmpty;

  double get totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.subtotal);

  int get totalItemCount =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadCart(String buyerId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _items = await _cartService.getCartItems(buyerId);
    } catch (e) {
      _errorMessage = 'Gagal memuat keranjang: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addItem(String buyerId, String menuId, {int quantity = 1}) async {
    try {
      await _cartService.addItem(buyerId: buyerId, menuId: menuId, quantity: quantity);
      await loadCart(buyerId);
    } catch (e) {
      _errorMessage = 'Gagal menambahkan ke keranjang: $e';
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String buyerId, String cartItemId, int quantity) async {
    try {
      await _cartService.updateQuantity(cartItemId, quantity);
      await loadCart(buyerId);
    } catch (e) {
      _errorMessage = 'Gagal mengubah jumlah: $e';
      notifyListeners();
    }
  }

  Future<void> removeItem(String buyerId, String cartItemId) async {
    try {
      await _cartService.removeItem(cartItemId);
      await loadCart(buyerId);
    } catch (e) {
      _errorMessage = 'Gagal menghapus item: $e';
      notifyListeners();
    }
  }

  /// Dipanggil setelah order berhasil dibuat di checkout_screen.dart
  Future<void> clearCart(String buyerId) async {
    await _cartService.clearCart(buyerId);
    _items = [];
    notifyListeners();
  }
}
