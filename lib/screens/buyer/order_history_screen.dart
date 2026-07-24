import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_status_badge.dart';
import 'order_tracking_screen.dart';

/// Menampilkan semua pesanan yang pernah dibuat pembeli, termasuk yang
/// sudah selesai maupun dibatalkan. Tap salah satu untuk melihat detail
/// statusnya di order_tracking_screen.dart (yang juga menangani tampilan
/// untuk pesanan selesai/dibatalkan).
class OrderHistoryScreen extends StatefulWidget {
  final String buyerId;

  const OrderHistoryScreen({super.key, required this.buyerId});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrderHistory(widget.buyerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.orderHistory.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.orderHistory.isEmpty) {
            return const Center(child: Text('Belum ada riwayat pesanan'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadOrderHistory(widget.buyerId),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: provider.orderHistory.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final order = provider.orderHistory[index];
                return _OrderHistoryTile(
                  order: order,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderTrackingScreen(orderId: order.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _OrderHistoryTile extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OrderHistoryTile({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Jam ambil: ${order.pickupTime}'),
            Text('Total: Rp ${order.totalAmount.toStringAsFixed(0)}'),
            Text(
              '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: OrderStatusBadge(status: order.status),
      ),
    );
  }
}
