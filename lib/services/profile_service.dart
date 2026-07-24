import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service khusus untuk upload foto profil ke storage.
/// Update data teks profil (nama, telepon) ditangani di auth_service.dart
/// karena satu tabel yang sama (public.users).
class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _bucket = 'profile-images';

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    final fileExt = imageFile.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final storagePath = '$userId/$fileName';

    await _client.storage.from(_bucket).upload(
          storagePath,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage.from(_bucket).getPublicUrl(storagePath);
  }
}
