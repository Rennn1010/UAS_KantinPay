enum PaymentMethod { qris, cod }

enum PaymentStatus { pending, waitingVerification, paid }

/// Konversi enum <-> string agar cocok dengan value di database Postgres
extension PaymentMethodX on PaymentMethod {
  String get value => this == PaymentMethod.qris ? 'qris' : 'cod';

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'qris':
        return PaymentMethod.qris;
      case 'cod':
        return PaymentMethod.cod;
      default:
        throw ArgumentError('Unknown payment method: $value');
    }
  }
}

extension PaymentStatusX on PaymentStatus {
  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.waitingVerification:
        return 'waiting_verification';
      case PaymentStatus.paid:
        return 'paid';
    }
  }

  static PaymentStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return PaymentStatus.pending;
      case 'waiting_verification':
        return PaymentStatus.waitingVerification;
      case 'paid':
        return PaymentStatus.paid;
      default:
        throw ArgumentError('Unknown payment status: $value');
    }
  }
}

class PaymentModel {
  final String id;
  final String orderId;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? qrisImageUrl;
  final DateTime? confirmedByBuyerAt;
  final DateTime? verifiedBySellerAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.method,
    required this.status,
    this.qrisImageUrl,
    this.confirmedByBuyerAt,
    this.verifiedBySellerAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      method: PaymentMethodX.fromString(map['method'] as String),
      status: PaymentStatusX.fromString(map['status'] as String),
      qrisImageUrl: map['qris_image_url'] as String?,
      confirmedByBuyerAt: map['confirmed_by_buyer_at'] != null
          ? DateTime.parse(map['confirmed_by_buyer_at'] as String)
          : null,
      verifiedBySellerAt: map['verified_by_seller_at'] != null
          ? DateTime.parse(map['verified_by_seller_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'order_id': orderId,
      'method': method.value,
      'status': status.value,
      if (qrisImageUrl != null) 'qris_image_url': qrisImageUrl,
    };
  }

  PaymentModel copyWith({
    PaymentStatus? status,
    DateTime? confirmedByBuyerAt,
    DateTime? verifiedBySellerAt,
  }) {
    return PaymentModel(
      id: id,
      orderId: orderId,
      method: method,
      status: status ?? this.status,
      qrisImageUrl: qrisImageUrl,
      confirmedByBuyerAt: confirmedByBuyerAt ?? this.confirmedByBuyerAt,
      verifiedBySellerAt: verifiedBySellerAt ?? this.verifiedBySellerAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
