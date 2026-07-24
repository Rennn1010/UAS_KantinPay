import 'package:flutter/material.dart';

/// Widget ini dipakai di payment_screen.dart untuk menampilkan
/// gambar QRIS statis milik penjual beserta tombol "Sudah Bayar".
class QrisDisplayWidget extends StatelessWidget {
  final String qrisImageUrl;
  final bool isConfirmed; // true jika pembeli sudah klik "Sudah Bayar"
  final bool isLoading;
  final VoidCallback onConfirmPayment;

  const QrisDisplayWidget({
    super.key,
    required this.qrisImageUrl,
    required this.isConfirmed,
    required this.onConfirmPayment,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Scan QR di bawah ini menggunakan aplikasi e-wallet/m-banking Anda',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              qrisImageUrl,
              width: 240,
              height: 240,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const SizedBox(
                  width: 240,
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                width: 240,
                height: 240,
                child: Center(child: Text('Gambar QR gagal dimuat')),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Catatan: QRIS ini hanya simulasi untuk keperluan akademik',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        const SizedBox(height: 20),
        if (!isConfirmed)
          ElevatedButton(
            onPressed: isLoading ? null : onConfirmPayment,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sudah Bayar'),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Menunggu penjual memverifikasi pembayaran',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}
