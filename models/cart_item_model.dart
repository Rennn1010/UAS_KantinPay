class CartItemModel {
  final String id; // id row di cart_items
  final String cartId;
  final String menuId;
  final String menuName;
  final String? menuImageUrl;
  final double price;
  final int quantity;
  final int availableStock;
  final String sellerId; // pemilik menu, dipakai saat checkout

  CartItemModel({
    required this.id,
    required this.cartId,
    required this.menuId,
    required this.menuName,
    this.menuImageUrl,
    required this.price,
    required this.quantity,
    required this.availableStock,
    required this.sellerId,
  });

  double get subtotal => price * quantity;

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    final menu = map['menus'] as Map<String, dynamic>?;
    return CartItemModel(
      id: map['id'] as String,
      cartId: map['cart_id'] as String,
      menuId: map['menu_id'] as String,
      menuName: menu?['name'] as String? ?? '',
      menuImageUrl: menu?['image_url'] as String?,
      price: (menu?['price'] as num?)?.toDouble() ?? 0,
      quantity: map['quantity'] as int,
      availableStock: (menu?['stock'] as num?)?.toInt() ?? 0,
      sellerId: menu?['seller_id'] as String? ?? '',
    );
  }

  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      id: id,
      cartId: cartId,
      menuId: menuId,
      menuName: menuName,
      menuImageUrl: menuImageUrl,
      price: price,
      quantity: quantity ?? this.quantity,
      availableStock: availableStock,
      sellerId: sellerId,
    );
  }
}
