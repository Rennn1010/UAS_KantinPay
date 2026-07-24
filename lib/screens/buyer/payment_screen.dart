import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/qris_display_widget.dart';

/// Screen ini muncul setelah checkout berhasil (order sudah dibuat).
/// Alur:
///  1. Pembeli pilih metode: QRIS atau COD
///  2. Jika QRIS -> tampilkan gambar QR penjual + tombol "Sudah Bayar"
///  3. Setelah dikonfirmasi, tunggu penjual verifikasi (realtime)
///  4. Jika COD -> langsung lanjut ke tracking pesanan
class PaymentScreen extends StatefulWidget {
  final String orderId;
  final String sellerId;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.sellerId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod? _selectedMethod;
  String? _qrisImageUrl;
  bool _loadingQris = false;

  @override
  void initState() {
    super.initState();
    // Dengarkan perubahan status pembayaran secara realtime
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().listenToPayment(widget.orderId);
    });
  }

  @override
  void dispose() {
    context.read<PaymentProvider>().stopListening();
    super.dispose();
  }

  Future<void> _selectQris() async {
    setState(() {
      _selectedMethod = PaymentMethod.qris;
      _loadingQris = true;
    });

    final provider = context.read<PaymentProvider>();
    final qrisUrl = await provider.fetchSellerQrisUrl(widget.sellerId);

    setState(() {
      _qrisImageUrl = qrisUrl;
      _loadingQris = false;
    });

    if (qrisUrl == null) return;

    await provider.createPayment(
      orderId: widget.orderId,
      method: PaymentMethod.qris,
      qrisImageUrl: qrisUrl,
    );
  }

  Future<void> _selectCod() async {
    setState(() => _selectedMethod = PaymentMethod.cod);

    final provider = context.read<PaymentProvider>();
    await provider.createPayment(
      orderId: widget.orderId,
      method: PaymentMethod.cod,
    );

    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      '/order-tracking',
      arguments: widget.orderId,
    );
  }

  Future<void> _confirmQrisPayment() async {
    final provider = context.read<PaymentProvider>();
    final success = await provider.confirmPaymentByBuyer();

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Gagal konfirmasi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Metode Pembayaran')),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, _) {
          final isConfirmed = paymentProvider.isWaitingVerification ||
              paymentProvider.isPaid;

          // Jika penjual sudah verifikasi -> lanjut otomatis ke tracking
          if (paymentProvider.isPaid) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(
                context,
                '/order-tracking',
                arguments: widget.orderId,
              );
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedMethod == null) ...[
                  const Text(
                    'Pilih metode pembayaran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  _PaymentMethodTile(
                    icon: Icons.qr_code,
                    title: 'QRIS (Simulasi)',
                    subtitle: 'Scan QR dan konfirmasi setelah bayar',
                    onTap: _selectQris,
                  ),
                  const SizedBox(height: 12),
                  _PaymentMethodTile(
                    icon: Icons.payments_outlined,
                    title: 'COD',
                    subtitle: 'Bayar saat mengambil pesanan',
                    onTap: _selectCod,
                  ),
                ] else if (_selectedMethod == PaymentMethod.qris) ...[
                  if (_loadingQris)
                    const Center(child: CircularProgressIndicator())
                  else if (_qrisImageUrl == null)
                    const Center(
                      child: Text('Penjual belum mengunggah QRIS'),
                    )
                  else
                    QrisDisplayWidget(
                      qrisImageUrl: _qrisImageUrl!,
                      isConfirmed: isConfirmed,
                      isLoading: paymentProvider.isLoading,
                      onConfirmPayment: _confirmQrisPayment,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
