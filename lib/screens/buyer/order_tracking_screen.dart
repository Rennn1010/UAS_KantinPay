import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_status_badge.dart';
import 'payment_screen.dart';

/// Menampilkan progres pesanan pembeli secara realtime:
/// Menunggu Pembayaran -> Menunggu Verifikasi -> Diproses -> Siap Diambil -> Selesai
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  static const List<OrderStatus> _timelineSteps = [
    OrderStatus.menungguPembayaran,
    OrderStatus.menungguVerifikasi,
    OrderStatus.diproses,
    OrderStatus.siapDiambil,
    OrderStatus.selesai,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().trackOrder(widget.orderId);
    });
  }

  @override
  void dispose() {
    context.read<OrderProvider>().stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Status Pesanan')),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          final order = provider.currentOrder;

          if (provider.isLoading && order == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (order == null) {
            return const Center(child: Text('Pesanan tidak ditemukan'));
          }

          if (order.status == OrderStatus.dibatalkan) {
            return _buildCancelledView(order);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    OrderStatusBadge(status: order.status),
                  ],
                ),
                Text('Jam ambil: ${order.pickupTime}'),
                const SizedBox(height: 24),
                _buildTimeline(order.status),
                const SizedBox(height: 24),
                const Text(
                  'Item Pesanan',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('${item.menuName} x${item.quantity}'),
                        ),
                        Text('Rp ${item.subtotal.toStringAsFixed(0)}'),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Rp ${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (order.status == OrderStatus.menungguPembayaran) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => PaymentScreen(
                                orderId: order.id,
                                sellerId: order.sellerId,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Bayar Sekarang'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCancelledView(OrderModel order) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cancel_outlined, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            'Pesanan ${order.orderNumber} dibatalkan',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(OrderStatus currentStatus) {
    final currentIndex = _timelineSteps.indexOf(currentStatus);

    return Column(
      children: List.generate(_timelineSteps.length, (index) {
        final step = _timelineSteps[index];
        final isDone = index <= currentIndex;
        final isLast = index == _timelineSteps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? Colors.green : Colors.grey.shade300,
                  ),
                  child:
                      isDone
                          ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                          : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 36,
                    color: isDone ? Colors.green : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                step.label,
                style: TextStyle(
                  fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                  color: isDone ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
