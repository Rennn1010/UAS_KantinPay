import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item_model.dart';

/// Service untuk mengelola keranjang belanja pembeli.
/// Satu pembeli hanya punya satu row di tabel `carts` (lihat unique index di schema).
class CartService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Ambil cart_id milik pembeli, buat baru jika belum ada
  Future<String> _getOrCreateCartId(String buyerId) async {
    final existing = await _client
        .from('carts')
        .select('id')
        .eq('buyer_id', buyerId)
        .maybeSingle();

    if (existing != null) return existing['id'] as String;

    final created = await _client
        .from('carts')
        .insert({'buyer_id': buyerId})
        .select('id')
        .single();

    return created['id'] as String;
  }

  /// Ambil semua item keranjang beserta info menu (join)
  Future<List<CartItemModel>> getCartItems(String buyerId) async {
    final cartId = await _getOrCreateCartId(buyerId);

    final response = await _client
        .from('cart_items')
        .select('*, menus(name, price, stock, image_url, seller_id)')
        .eq('cart_id', cartId);

    return (response as List)
        .map((row) => CartItemModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Tambah menu ke keranjang. Jika menu sudah ada, tambahkan quantity-nya.
  Future<void> addItem({
    required String buyerId,
    required String menuId,
    int quantity = 1,
  }) async {
    final cartId = await _getOrCreateCartId(buyerId);

    final existing = await _client
        .from('cart_items')
        .select('id, quantity')
        .eq('cart_id', cartId)
        .eq('menu_id', menuId)
        .maybeSingle();

    if (existing != null) {
      await _client.from('cart_items').update({
        'quantity': (existing['quantity'] as int) + quantity,
      }).eq('id', existing['id']);
    } else {
      await _client.from('cart_items').insert({
        'cart_id': cartId,
        'menu_id': menuId,
        'quantity': quantity,
      });
    }
  }

  /// Ubah jumlah item. Jika quantity <= 0, item dihapus.
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(cartItemId);
      return;
    }
    await _client
        .from('cart_items')
        .update({'quantity': quantity}).eq('id', cartItemId);
  }

  Future<void> removeItem(String cartItemId) async {
    await _client.from('cart_items').delete().eq('id', cartItemId);
  }

  /// Kosongkan keranjang setelah checkout berhasil
  Future<void> clearCart(String buyerId) async {
    final cartId = await _getOrCreateCartId(buyerId);
    await _client.from('cart_items').delete().eq('cart_id', cartId);
  }
}
