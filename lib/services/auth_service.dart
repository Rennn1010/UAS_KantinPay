import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// Service ini menangani registrasi, login, logout, dan pengambilan
/// profil pengguna. Supabase Auth menyimpan kredensial di auth.users,
/// sedangkan data profil (nama, role, dll) disimpan terpisah di public.users.
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentAuthUser => _client.auth.currentUser;
  bool get isLoggedIn => currentAuthUser != null;

  /// Registrasi akun baru + buat profil di tabel users
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final authUser = authResponse.user;
    if (authUser == null) {
      throw Exception('Registrasi gagal, silakan coba lagi');
    }

    final profileResponse = await _client
        .from('users')
        .insert({
          'id': authUser.id,
          'full_name': fullName,
          'email': email,
          'role': role.value,
        })
        .select()
        .single();

    return UserModel.fromMap(profileResponse);
  }

  /// Login dengan email & password
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final authResponse = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final authUser = authResponse.user;
    if (authUser == null) {
      throw Exception('Email atau password salah');
    }

    return getProfile(authUser.id);
  }

  /// Ambil data profil (nama, role, dll) dari tabel users
  Future<UserModel> getProfile(String userId) async {
    final response =
        await _client.from('users').select().eq('id', userId).single();
    return UserModel.fromMap(response);
  }

  /// Update data profil (nama, telepon, foto). Field yang null diabaikan
  /// (tidak menimpa data lama), kecuali profileImageUrl yang memang
  /// dikirim setelah upload berhasil di profile_service.dart.
  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? profileImageUrl,
  }) async {
    final payload = <String, dynamic>{
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
    };

    final response = await _client
        .from('users')
        .update(payload)
        .eq('id', userId)
        .select()
        .single();

    return UserModel.fromMap(response);
  }

  /// Cek sesi aktif saat splash screen — dipanggil untuk auto-login
  Future<UserModel?> getCurrentSessionProfile() async {
    final authUser = currentAuthUser;
    if (authUser == null) return null;
    try {
      return await getProfile(authUser.id);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }
}
