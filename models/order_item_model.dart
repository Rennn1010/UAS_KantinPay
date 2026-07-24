class OrderItemModel {
  final String id;
  final String orderId;
  final String menuId;
  final String menuName;
  final double price;
  final int quantity;
  final double subtotal;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.menuId,
    required this.menuName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      menuId: map['menu_id'] as String,
      menuName: map['menu_name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }
}
