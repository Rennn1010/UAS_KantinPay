import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_model.dart';
import '../models/category_model.dart';

/// Service untuk membaca menu & kategori. Dipakai di sisi pembeli (browsing).
/// Untuk kelola menu (CRUD penjual), lihat seller_menu_service.dart.
class MenuService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<CategoryModel>> getCategories() async {
    final response = await _client.from('categories').select().order('name');
    return (response as List)
        .map((row) => CategoryModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Ambil semua menu aktif, opsional difilter kategori dan kata kunci pencarian
  Future<List<MenuModel>> getMenus({
    String? categoryId,
    String? searchQuery,
  }) async {
    var query = _client
        .from('menus')
        .select('*, categories(name)')
        .eq('is_active', true);

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query = query.ilike('name', '%${searchQuery.trim()}%');
    }

    final response = await query.order('name');

    return (response as List)
        .map((row) => MenuModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<MenuModel> getMenuById(String menuId) async {
    final response = await _client
        .from('menus')
        .select('*, categories(name)')
        .eq('id', menuId)
        .single();
    return MenuModel.fromMap(response);
  }

  /// Realtime stream stok menu — dipakai di menu_detail_screen.dart (4.12)
  Stream<int> watchMenuStock(String menuId) {
    return _client
        .from('menus')
        .stream(primaryKey: ['id'])
        .eq('id', menuId)
        .map((rows) => rows.isEmpty ? 0 : rows.first['stock'] as int);
  }
}
