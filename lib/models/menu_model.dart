class MenuModel {
  final String id;
  final String sellerId;
  final String? categoryId;
  final String? categoryName; // hasil join, untuk ditampilkan
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? imageUrl;
  final bool isActive;

  MenuModel({
    required this.id,
    required this.sellerId,
    this.categoryId,
    this.categoryName,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
    required this.isActive,
  });

  bool get isAvailable => isActive && stock > 0;

  factory MenuModel.fromMap(Map<String, dynamic> map) {
    final category = map['categories'] as Map<String, dynamic>?;
    return MenuModel(
      id: map['id'] as String,
      sellerId: map['seller_id'] as String,
      categoryId: map['category_id'] as String?,
      categoryName: category?['name'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      stock: map['stock'] as int,
      imageUrl: map['image_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
