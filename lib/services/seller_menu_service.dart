import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_model.dart';

/// Service untuk kelola menu milik penjual (tambah, edit, hapus, update stok).
/// Berbeda dari menu_service.dart yang read-only untuk sisi pembeli.
class SellerMenuService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _bucket = 'menu-images';

  String _contentTypeFor(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  /// Ambil semua menu milik penjual (termasuk yang nonaktif/habis stok)
  Future<List<MenuModel>> getMenusBySeller(String sellerId) async {
    final response = await _client
        .from('menus')
        .select('*, categories(name)')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => MenuModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Upload foto menu ke storage, mengembalikan public URL.
  /// Pakai uploadBinary (bytes) alih-alih upload(File) agar kompatibel
  /// dengan Flutter Web, di mana dart:io File tidak tersedia.
  Future<String> _uploadImage(
    String sellerId,
    Uint8List imageBytes,
    String originalFileName,
  ) async {
    final fileExt = originalFileName.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final storagePath = '$sellerId/$fileName';

    await _client.storage
        .from(_bucket)
        .uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: FileOptions(contentType: _contentTypeFor(fileExt)),
        );
    return _client.storage.from(_bucket).getPublicUrl(storagePath);
  }

  /// Tambah menu baru. imageFile opsional (menu bisa dibuat tanpa foto dulu).
  Future<MenuModel> createMenu({
    required String sellerId,
    String? categoryId,
    required String name,
    String? description,
    required double price,
    required int stock,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    String? imageUrl;
    if (imageBytes != null && imageName != null) {
      imageUrl = await _uploadImage(sellerId, imageBytes, imageName);
    }

    final response = await _client
        .from('menus')
        .insert({
          'seller_id': sellerId,
          'category_id': categoryId,
          'name': name,
          'description': description,
          'price': price,
          'stock': stock,
          'image_url': imageUrl,
          'is_active': true,
        })
        .select('*, categories(name)')
        .single();

    return MenuModel.fromMap(response);
  }

  /// Edit menu yang sudah ada. Jika imageFile diisi, foto lama diganti.
  Future<MenuModel> updateMenu({
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
    String? imageUrl = existingImageUrl;
    if (imageBytes != null && imageName != null) {
      imageUrl = await _uploadImage(sellerId, imageBytes, imageName);
    }

    final response = await _client
        .from('menus')
        .update({
          'category_id': categoryId,
          'name': name,
          'description': description,
          'price': price,
          'stock': stock,
          'image_url': imageUrl,
        })
        .eq('id', menuId)
        .select('*, categories(name)')
        .single();

    return MenuModel.fromMap(response);
  }

  /// Aktifkan/nonaktifkan menu (dipakai untuk "sembunyikan" tanpa hapus data pesanan lama)
  Future<void> toggleActive(String menuId, bool isActive) async {
    await _client
        .from('menus')
        .update({'is_active': isActive}).eq('id', menuId);
  }

  /// Update stok cepat (misalnya lewat tombol +/- di list)
  Future<void> updateStock(String menuId, int newStock) async {
    await _client
        .from('menus')
        .update({'stock': newStock}).eq('id', menuId);
  }

  /// Hapus menu permanen. Hati-hati: akan gagal jika menu masih dirujuk
  /// oleh order_items lama (foreign key restrict) — pakai toggleActive
  /// sebagai alternatif yang lebih aman untuk menu yang sudah pernah terjual.
  Future<void> deleteMenu(String menuId) async {
    await _client.from('menus').delete().eq('id', menuId);
  }
}
