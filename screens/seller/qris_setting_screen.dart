import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/seller_qris_provider.dart';

class QrisSettingScreen extends StatefulWidget {
  final String sellerId;

  const QrisSettingScreen({super.key, required this.sellerId});

  @override
  State<QrisSettingScreen> createState() => _QrisSettingScreenState();
}

class _QrisSettingScreenState extends State<QrisSettingScreen> {
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerQrisProvider>().loadQris(widget.sellerId);
    });
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _saveQris() async {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gambar QRIS terlebih dahulu')),
      );
      return;
    }

    final provider = context.read<SellerQrisProvider>();
    final success = await provider.uploadQris(
      sellerId: widget.sellerId,
      imageFile: _pickedImage!,
    );

    if (!mounted) return;

    if (success) {
      setState(() => _pickedImage = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QRIS berhasil disimpan')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Gagal menyimpan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan QRIS')),
      body: Consumer<SellerQrisProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.qris == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentImageUrl = provider.qris?.qrisImageUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'QR ini akan ditampilkan ke pembeli saat memilih metode pembayaran QRIS.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_pickedImage!, fit: BoxFit.cover),
                        )
                      : (currentImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                currentImageUrl,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Center(
                              child: Text('Belum ada QRIS diunggah'),
                            )),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    currentImageUrl == null ? 'Pilih Gambar QR' : 'Ganti Gambar QR',
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: provider.isLoading ? null : _saveQris,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan QRIS'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
