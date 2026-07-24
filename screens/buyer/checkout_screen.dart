import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../widgets/time_picker_widget.dart';
import 'payment_screen.dart';

/// Alur: Keranjang -> Checkout (halaman ini) -> pilih jam ambil -> buat order -> PaymentScreen
/// Catatan: untuk kesederhanaan, checkout diasumsikan satu keranjang = satu penjual
/// (umum untuk kasus kantin tunggal). Jika ke depan mendukung multi-kantin,
/// keranjang perlu dikelompokkan per seller_id sebelum checkout.
class CheckoutScreen extends StatefulWidget {
  final String buyerId;

  const CheckoutScreen({super.key, required this.buyerId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderService _orderService = OrderService();
  String? _selectedTime;
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _submitOrder() async {
    final cartProvider = context.read<CartProvider>();

    if (_selectedTime == null) {
      setState(() => _errorMessage = 'Pilih jam pengambilan terlebih dahulu');
      return;
    }
    if (cartProvider.items.isEmpty) {
      setState(() => _errorMessage = 'Keranjang kosong');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final sellerId = cartProvider.items.first.sellerId;

      final order = await _orderService.createOrder(
        buyerId: widget.buyerId,
        sellerId: sellerId,
        pickupTime: _selectedTime!,
        cartItems: cartProvider.items,
      );

      // Kosongkan keranjang setelah order berhasil dibuat
      await cartProvider.clearCart(widget.buyerId);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            orderId: order.id,
            sellerId: order.sellerId,
          ),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Gagal membuat pesanan: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          if (cartProvider.isEmpty) {
            return const Center(child: Text('Keranjang kosong'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Ringkasan Pesanan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...cartProvider.items.map(
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
                      'Rp ${cartProvider.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Pilih Jam Pengambilan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TimePickerWidget(
                  selectedSlot: _selectedTime,
                  onSelected: (slot) => setState(() => _selectedTime = slot),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Buat Pesanan'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
