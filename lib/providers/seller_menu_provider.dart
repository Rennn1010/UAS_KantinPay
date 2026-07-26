import 'package:flutter/foundation.dart';
import '../models/menu_model.dart';
import '../services/seller_menu_service.dart';

class SellerMenuProvider extends ChangeNotifier {
  final SellerMenuService _service = SellerMenuService();

  List<MenuModel> _menus = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MenuModel> get menus => _menus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadMenus(String sellerId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _menus = await _service.getMenusBySeller(sellerId);
    } catch (e) {
      _errorMessage = 'Gagal memuat menu: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createMenu({
    required String sellerId,
    String? categoryId,
    required String name,
    String? description,
    required double price,
    required int stock,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _service.createMenu(
        sellerId: sellerId,
        categoryId: categoryId,
        name: name,
        description: description,
        price: price,
        stock: stock,
        imageBytes: imageBytes,
        imageName: imageName,
      );
      await loadMenus(sellerId);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambah menu: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateMenu({
    required String menuId,
    required String sellerId,
    String? categoryId,
    required String name,
    String? description,
    required double price,
    required int stock,
    Uint8List? imageBytes,
    String? imageName,
    String? existingImageUrl,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _service.updateMenu(
        menuId: menuId,
        sellerId: sellerId,
        categoryId: categoryId,
        name: name,
        description: description,
        price: price,
        stock: stock,
        imageBytes: imageBytes,
        imageName: imageName,
        existingImageUrl: existingImageUrl,
      );
      await loadMenus(sellerId);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan perubahan: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> toggleActive(String sellerId, String menuId, bool isActive) async {
    try {
      await _service.toggleActive(menuId, isActive);
      await loadMenus(sellerId);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengubah status menu: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMenu(String sellerId, String menuId) async {
    try {
      await _service.deleteMenu(menuId);
      await loadMenus(sellerId);
      return true;
    } catch (e) {
      _errorMessage =
          'Gagal menghapus menu (mungkin sudah pernah dipesan). Coba nonaktifkan saja.';
      notifyListeners();
      return false;
    }
  }
}
