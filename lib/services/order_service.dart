import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/cart_item_model.dart';

/// Service umum untuk tabel orders & order_items.
/// Dipakai baik oleh sisi pembeli (tracking, history) maupun penjual (kelola pesanan).
class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Dipanggil dari checkout_screen.dart setelah pembeli memilih jam ambil.
  /// Membuat order + order_items dari isi keranjang, nomor pesanan
  /// dibuat otomatis lewat fungsi database generate_order_number().
  /// Stok menu berkurang otomatis lewat trigger di database (reduce_stock_on_order).
  Future<OrderModel> createOrder({
    required String buyerId,
    required String sellerId,
    required String pickupTime,
    required List<CartItemModel> cartItems,
    String? notes,
  }) async {
    if (cartItems.isEmpty) {
      throw Exception('Keranjang kosong, tidak bisa checkout');
    }

    // Panggil function SQL generate_order_number() untuk dapat nomor unik
    final orderNumber =
        await _client.rpc('generate_order_number') as String;

    final totalAmount =
        cartItems.fold<double>(0, (sum, item) => sum + item.subtotal);

    final orderResponse = await _client
        .from('orders')
        .insert({
          'order_number': orderNumber,
          'buyer_id': buyerId,
          'seller_id': sellerId,
          'pickup_time': pickupTime,
          'total_amount': totalAmount,
          'status': 'menunggu_pembayaran',
          if (notes != null) 'notes': notes,
        })
        .select()
        .single();

    final orderId = orderResponse['id'] as String;

    final itemsPayload = cartItems
        .map((item) => {
              'order_id': orderId,
              'menu_id': item.menuId,
              'menu_name': item.menuName,
              'price': item.price,
              'quantity': item.quantity,
              'subtotal': item.subtotal,
            })
        .toList();

    // Insert order_items -> trigger di database otomatis mengurangi stok menu
    await _client.from('order_items').insert(itemsPayload);

    return getOrderById(orderId);
  }

  /// Ambil satu order lengkap dengan item-itemnya + nama pembeli (join)
  Future<OrderModel> getOrderById(String orderId) async {
    final orderResponse = await _client
        .from('orders')
        .select('*, users!orders_buyer_id_fkey(full_name)')
        .eq('id', orderId)
        .single();

    final itemsResponse = await _client
        .from('order_items')
        .select()
        .eq('order_id', orderId);

    final items = (itemsResponse as List)
        .map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>))
        .toList();

    final buyerName =
        (orderResponse['users'] as Map<String, dynamic>?)?['full_name'] as String?;

    return OrderModel.fromMap(
      {...orderResponse, 'buyer_name': buyerName},
      items: items,
    );
  }

  /// Daftar pesanan milik seorang penjual, terbaru di atas
  Future<List<OrderModel>> getOrdersBySeller(
    String sellerId, {
    OrderStatus? filterStatus,
  }) async {
    var query = _client
        .from('orders')
        .select('*, users!orders_buyer_id_fkey(full_name)')
        .eq('seller_id', sellerId);

    if (filterStatus != null) {
      query = query.eq('status', filterStatus.value);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List).map((row) {
      final buyerName =
          (row['users'] as Map<String, dynamic>?)?['full_name'] as String?;
      return OrderModel.fromMap({...row, 'buyer_name': buyerName});
    }).toList();
  }

  /// Daftar riwayat pesanan milik pembeli
  Future<List<OrderModel>> getOrdersByBuyer(String buyerId) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('buyer_id', buyerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => OrderModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Update status pesanan (dipanggil penjual: diproses, siap_diambil, selesai, dibatalkan)
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _client
        .from('orders')
        .update({'status': status.value}).eq('id', orderId);
  }

  /// Realtime stream status pesanan tunggal — dipakai di order_tracking_screen (pembeli)
  /// dan order_detail_screen (penjual) agar update otomatis tanpa refresh manual.
  Stream<OrderModel> watchOrderById(String orderId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .asyncMap((rows) => getOrderById(orderId));
  }
}
