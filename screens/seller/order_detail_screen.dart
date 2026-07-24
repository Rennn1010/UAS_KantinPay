import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/seller_order_provider.dart';
import '../../widgets/order_status_badge.dart';

/// Halaman ini menampilkan detail satu pesanan bagi penjual, dengan aksi:
/// - Verifikasi pembayaran (untuk QRIS, setelah pembeli klik "Sudah Bayar")
/// - Ubah status pesanan (diproses -> siap_diambil -> selesai)
/// - Batalkan pesanan
class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerOrderProvider>().watchOrderDetail(widget.orderId);
      context.read<PaymentProvider>().loadPaymentByOrderId(widget.orderId);
      context.read<PaymentProvider>().listenToPayment(widget.orderId);
    });
  }

  @override
  void dispose() {
    context.read<SellerOrderProvider>().stopWatchingDetail();
    context.read<PaymentProvider>().stopListening();
    super.dispose();
  }

  Future<void> _verifyPayment() async {
    final paymentProvider = context.read<PaymentProvider>();
    final success = await paymentProvider.verifyPaymentBySeller();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil diverifikasi')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(paymentProvider.errorMessage ?? 'Gagal verifikasi')),
      );
    }
  }

  Future<void> _updateStatus(OrderStatus status) async {
    final orderProvider = context.read<SellerOrderProvider>();
    final success = await orderProvider.updateStatus(widget.orderId, status);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderProvider.errorMessage ?? 'Gagal update status')),
      );
    }
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pesanan'),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus(OrderStatus.dibatalkan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: Consumer2<SellerOrderProvider, PaymentProvider>(
        builder: (context, orderProvider, paymentProvider, _) {
          final order = orderProvider.selectedOrder;

          if (orderProvider.isLoading && order == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (order == null) {
            return const Center(child: Text('Pesanan tidak ditemukan'));
          }

          final payment = paymentProvider.payment;

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
                const SizedBox(height: 4),
                Text('Pembeli: ${order.buyerName ?? '-'}'),
                Text('Jam ambil: ${order.pickupTime}'),
                const Divider(height: 24),

                const Text('Item Pesanan', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${item.menuName} x${item.quantity}')),
                        Text('Rp ${item.subtotal.toStringAsFixed(0)}'),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'Rp ${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (payment != null) ...[
                  const Text('Status Pembayaran', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Metode: ${payment.method == PaymentMethod.qris ? 'QRIS' : 'COD'}'),
                  Text('Status: ${_paymentStatusLabel(payment.status)}'),
                  const SizedBox(height: 12),
                  if (payment.method == PaymentMethod.qris &&
                      payment.status == PaymentStatus.waitingVerification)
                    ElevatedButton(
                      onPressed: paymentProvider.isLoading ? null : _verifyPayment,
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: paymentProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Verifikasi Pembayaran'),
                    ),
                  const SizedBox(height: 20),
                ],

                const Text('Ubah Status Pesanan', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildStatusActions(order.status),

                const SizedBox(height: 24),
                if (order.status != OrderStatus.selesai &&
                    order.status != OrderStatus.dibatalkan)
                  OutlinedButton(
                    onPressed: _confirmCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Batalkan Pesanan'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _paymentStatusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Menunggu Pembayaran';
      case PaymentStatus.waitingVerification:
        return 'Menunggu Verifikasi';
      case PaymentStatus.paid:
        return 'Lunas';
    }
  }

  Widget _buildStatusActions(OrderStatus current) {
    // Tombol hanya muncul sesuai urutan alur status yang valid berikutnya
    switch (current) {
      case OrderStatus.diproses:
        return ElevatedButton(
          onPressed: () => _updateStatus(OrderStatus.siapDiambil),
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Tandai Siap Diambil'),
        );
      case OrderStatus.siapDiambil:
        return ElevatedButton(
          onPressed: () => _updateStatus(OrderStatus.selesai),
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Tandai Selesai'),
        );
      case OrderStatus.menungguPembayaran:
      case OrderStatus.menungguVerifikasi:
        return const Text(
          'Menunggu proses pembayaran sebelum bisa diproses',
          style: TextStyle(color: Colors.grey),
        );
      case OrderStatus.selesai:
      case OrderStatus.dibatalkan:
        return const SizedBox.shrink();
    }
  }
}
