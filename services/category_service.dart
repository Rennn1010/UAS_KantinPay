import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';

/// Kategori bersifat global (dipakai bersama semua penjual), sesuai
/// tabel categories di schema yang tidak punya kolom seller_id.
/// Jika ke depan tiap penjual butuh kategori sendiri, tambahkan
/// kolom seller_id di tabel categories dan filter di sini.
class CategoryService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<CategoryModel>> getCategories() async {
    final response = await _client.from('categories').select().order('name');
    return (response as List)
        .map((row) => CategoryModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryModel> createCategory(String name) async {
    final response =
        await _client.from('categories').insert({'name': name}).select().single();
    return CategoryModel.fromMap(response);
  }

  Future<CategoryModel> updateCategory(String id, String name) async {
    final response = await _client
        .from('categories')
        .update({'name': name})
        .eq('id', id)
        .select()
        .single();
    return CategoryModel.fromMap(response);
  }

  /// Hapus kategori. Jika masih dipakai menu (foreign key set null),
  /// menu terkait otomatis jadi tanpa kategori, bukan ikut terhapus.
  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }
}
