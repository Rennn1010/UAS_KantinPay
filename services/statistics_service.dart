import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/statistics_model.dart';

/// Semua agregasi dilakukan di sisi client (Dart) dari data mentah orders
/// & order_items. Untuk skala data UAS/kantin ini cukup ringan; jika volume
/// transaksi jadi besar, pertimbangkan pindah ke SQL view atau RPC function.
class StatisticsService {
  final SupabaseClient _client = Supabase.instance.client;

  /// 5.3 Statistik Penjualan: total pesanan, total transaksi, produk terjual
  Future<SalesSummaryModel> getSummary(String sellerId) async {
    final ordersResponse = await _client
        .from('orders')
        .select('id, total_amount, status')
        .eq('seller_id', sellerId);

    final orders = (ordersResponse as List)
        .where((o) => o['status'] != 'dibatalkan')
        .toList();

    final totalOrders = orders.length;
    final totalTransactionValue = orders.fold<double>(
      0,
      (sum, o) => sum + (o['total_amount'] as num).toDouble(),
    );

    final itemsResponse = await _client
        .from('order_items')
        .select('quantity, orders!inner(seller_id, status)')
        .eq('orders.seller_id', sellerId);

    final totalItemsSold = (itemsResponse as List)
        .where((i) => (i['orders'] as Map)['status'] != 'dibatalkan')
        .fold<int>(0, (sum, i) => sum + (i['quantity'] as int));

    return SalesSummaryModel(
      totalOrders: totalOrders,
      totalTransactionValue: totalTransactionValue,
      totalItemsSold: totalItemsSold,
    );
  }

  /// 5.4 Menu Terlaris: urutan produk berdasarkan jumlah penjualan tertinggi
  Future<List<BestSellerItem>> getBestSellers(
    String sellerId, {
    int limit = 10,
  }) async {
    final response = await _client
        .from('order_items')
        .select('menu_name, quantity, orders!inner(seller_id, status)')
        .eq('orders.seller_id', sellerId);

    final Map<String, int> totals = {};
    for (final row in response as List) {
      final status = (row['orders'] as Map)['status'];
      if (status == 'dibatalkan') continue;
      final name = row['menu_name'] as String;
      final qty = row['quantity'] as int;
      totals[name] = (totals[name] ?? 0) + qty;
    }

    final list = totals.entries
        .map((e) => BestSellerItem(menuName: e.key, totalQuantity: e.value))
        .toList()
      ..sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

    return list.take(limit).toList();
  }

  /// 5.5 Analisis Jam Ramai: jumlah transaksi per slot jam ambil
  Future<List<PeakHourItem>> getPeakHours(String sellerId) async {
    final response = await _client
        .from('orders')
        .select('pickup_time, status')
        .eq('seller_id', sellerId);

    final Map<String, int> counts = {};
    for (final row in response as List) {
      if (row['status'] == 'dibatalkan') continue;
      final rawTime = row['pickup_time'] as String; // format "09:00:00"
      final hourLabel = rawTime.length >= 5 ? rawTime.substring(0, 5) : rawTime;
      counts[hourLabel] = (counts[hourLabel] ?? 0) + 1;
    }

    final list = counts.entries
        .map((e) => PeakHourItem(hourLabel: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.hourLabel.compareTo(b.hourLabel));

    return list;
  }
}
