import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _service = CategoryService();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _categories = await _service.getCategories();
    } catch (e) {
      _errorMessage = 'Gagal memuat kategori: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addCategory(String name) async {
    try {
      await _service.createCategory(name);
      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambah kategori: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> editCategory(String id, String name) async {
    try {
      await _service.updateCategory(id, name);
      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengubah kategori: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeCategory(String id) async {
    try {
      await _service.deleteCategory(id);
      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus kategori: $e';
      notifyListeners();
      return false;
    }
  }
}
