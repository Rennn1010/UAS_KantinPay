import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case OrderStatus.menungguPembayaran:
        return Colors.orange;
      case OrderStatus.menungguVerifikasi:
        return Colors.amber;
      case OrderStatus.diproses:
        return Colors.blue;
      case OrderStatus.siapDiambil:
        return Colors.teal;
      case OrderStatus.selesai:
        return Colors.green;
      case OrderStatus.dibatalkan:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
