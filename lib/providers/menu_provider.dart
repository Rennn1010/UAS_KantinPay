import 'package:flutter/foundation.dart';
import '../models/menu_model.dart';
import '../models/category_model.dart';
import '../services/menu_service.dart';

class MenuProvider extends ChangeNotifier {
  final MenuService _menuService = MenuService();

  List<CategoryModel> _categories = [];
  List<MenuModel> _menus = [];
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<CategoryModel> get categories => _categories;
  List<MenuModel> get menus => _menus;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Dipanggil sekali saat home_screen.dart dibuka
  Future<void> loadInitialData() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _categories = await _menuService.getCategories();
      _menus = await _menuService.getMenus();
    } catch (e) {
      _errorMessage = 'Gagal memuat menu: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> filterByCategory(String? categoryId) async {
    _selectedCategoryId = categoryId;
    await _reloadMenus();
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    await _reloadMenus();
  }

  Future<void> _reloadMenus() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _menus = await _menuService.getMenus(
        categoryId: _selectedCategoryId,
        searchQuery: _searchQuery,
      );
    } catch (e) {
      _errorMessage = 'Gagal memuat menu: $e';
    } finally {
      _setLoading(false);
    }
  }
}
