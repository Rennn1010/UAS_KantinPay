import 'order_item_model.dart';

enum OrderStatus {
  menungguPembayaran,
  menungguVerifikasi,
  diproses,
  siapDiambil,
  selesai,
  dibatalkan,
}

extension OrderStatusX on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.menungguPembayaran:
        return 'menunggu_pembayaran';
      case OrderStatus.menungguVerifikasi:
        return 'menunggu_verifikasi';
      case OrderStatus.diproses:
        return 'diproses';
      case OrderStatus.siapDiambil:
        return 'siap_diambil';
      case OrderStatus.selesai:
        return 'selesai';
      case OrderStatus.dibatalkan:
        return 'dibatalkan';
    }
  }

  /// Label untuk ditampilkan ke user
  String get label {
    switch (this) {
      case OrderStatus.menungguPembayaran:
        return 'Menunggu Pembayaran';
      case OrderStatus.menungguVerifikasi:
        return 'Menunggu Verifikasi';
      case OrderStatus.diproses:
        return 'Diproses';
      case OrderStatus.siapDiambil:
        return 'Siap Diambil';
      case OrderStatus.selesai:
        return 'Selesai';
      case OrderStatus.dibatalkan:
        return 'Dibatalkan';
    }
  }

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'menunggu_pembayaran':
        return OrderStatus.menungguPembayaran;
      case 'menunggu_verifikasi':
        return OrderStatus.menungguVerifikasi;
      case 'diproses':
        return OrderStatus.diproses;
      case 'siap_diambil':
        return OrderStatus.siapDiambil;
      case 'selesai':
        return OrderStatus.selesai;
      case 'dibatalkan':
        return OrderStatus.dibatalkan;
      default:
        throw ArgumentError('Unknown order status: $value');
    }
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String buyerId;
  final String sellerId;
  final String? buyerName; // hasil join, dipakai di order_detail_screen (seller)
  final String pickupTime;
  final double totalAmount;
  final OrderStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.buyerId,
    required this.sellerId,
    this.buyerName,
    required this.pickupTime,
    required this.totalAmount,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory OrderModel.fromMap(
    Map<String, dynamic> map, {
    List<OrderItemModel> items = const [],
  }) {
    return OrderModel(
      id: map['id'] as String,
      orderNumber: map['order_number'] as String,
      buyerId: map['buyer_id'] as String,
      sellerId: map['seller_id'] as String,
      buyerName: map['buyer_name'] as String?,
      pickupTime: map['pickup_time'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      status: OrderStatusX.fromString(map['status'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      items: items,
    );
  }

  OrderModel copyWith({OrderStatus? status, List<OrderItemModel>? items}) {
    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      buyerId: buyerId,
      sellerId: sellerId,
      buyerName: buyerName,
      pickupTime: pickupTime,
      totalAmount: totalAmount,
      status: status ?? this.status,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      items: items ?? this.items,
    );
  }
}
