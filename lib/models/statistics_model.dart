/// Ringkasan statistik penjualan (dipakai di statistics_screen.dart)
class SalesSummaryModel {
  final int totalOrders;
  final double totalTransactionValue;
  final int totalItemsSold;

  SalesSummaryModel({
    required this.totalOrders,
    required this.totalTransactionValue,
    required this.totalItemsSold,
  });
}

/// Satu baris menu terlaris (dipakai di best_seller_screen.dart)
class BestSellerItem {
  final String menuName;
  final int totalQuantity;

  BestSellerItem({required this.menuName, required this.totalQuantity});
}

/// Satu slot jam dengan jumlah transaksinya (dipakai di peak_hour_screen.dart)
class PeakHourItem {
  final String hourLabel; // contoh: "11:00"
  final int count;

  PeakHourItem({required this.hourLabel, required this.count});
}
