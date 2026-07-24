class SellerQrisModel {
  final String id;
  final String sellerId;
  final String qrisImageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SellerQrisModel({
    required this.id,
    required this.sellerId,
    required this.qrisImageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SellerQrisModel.fromMap(Map<String, dynamic> map) {
    return SellerQrisModel(
      id: map['id'] as String,
      sellerId: map['seller_id'] as String,
      qrisImageUrl: map['qris_image_url'] as String,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
