import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service khusus untuk upload foto profil ke storage.
/// Update data teks profil (nama, telepon) ditangani di auth_service.dart
/// karena satu tabel yang sama (public.users).
class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _bucket = 'profile-images';

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

  /// Upload lewat bytes (uploadBinary), bukan File, supaya jalan di
  /// Flutter Web (dart:io File tidak tersedia di web).
  Future<String> uploadProfileImage(
    String userId,
    Uint8List imageBytes,
    String originalFileName,
  ) async {
    final fileExt = originalFileName.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final storagePath = '$userId/$fileName';

    await _client.storage.from(_bucket).uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeFor(fileExt),
          ),
        );

    return _client.storage.from(_bucket).getPublicUrl(storagePath);
  }
}
