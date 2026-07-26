import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/seller_qris_model.dart';

/// Service untuk mengelola gambar QRIS statis milik penjual.
/// Bucket storage yang dipakai: 'qris-images'
class SellerQrisService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _bucket = 'qris-images';

  String _contentTypeFor(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  /// Ambil data QRIS aktif milik penjual (untuk ditampilkan di halaman setting)
  Future<SellerQrisModel?> getSellerQris(String sellerId) async {
    final response = await _client
        .from('seller_qris')
        .select()
        .eq('seller_id', sellerId)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return SellerQrisModel.fromMap(response);
  }

  /// Upload file gambar QR ke storage, lalu simpan/update record di tabel seller_qris.
  /// Jika penjual sudah pernah upload sebelumnya, record lama akan di-update (bukan duplikat).
  Future<SellerQrisModel> uploadQrisImage({
    required String sellerId,
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    final fileExt = imageName.split('.').last;
    final fileName =
        'qris_$sellerId${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final storagePath = '$sellerId/$fileName';

    // Upload ke Supabase Storage lewat bytes (kompatibel dengan Flutter Web)
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: FileOptions(contentType: _contentTypeFor(fileExt)),
        );

    final publicUrl = _client.storage.from(_bucket).getPublicUrl(storagePath);

    // Cek apakah penjual sudah punya record QRIS
    final existing = await getSellerQris(sellerId);

    if (existing != null) {
      final response = await _client
          .from('seller_qris')
          .update({'qris_image_url': publicUrl, 'is_active': true})
          .eq('id', existing.id)
          .select()
          .single();
      return SellerQrisModel.fromMap(response);
    } else {
      final response = await _client
          .from('seller_qris')
          .insert({
            'seller_id': sellerId,
            'qris_image_url': publicUrl,
            'is_active': true,
          })
          .select()
          .single();
      return SellerQrisModel.fromMap(response);
    }
  }

  /// Nonaktifkan QRIS lama (opsional, jika ingin sembunyikan tanpa hapus)
  Future<void> deactivateQris(String qrisId) async {
    await _client
        .from('seller_qris')
        .update({'is_active': false}).eq('id', qrisId);
  }
}
