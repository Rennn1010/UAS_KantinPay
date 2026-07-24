import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isSeller => _currentUser?.role == UserRole.penjual;
  bool get isBuyer => _currentUser?.role == UserRole.pembeli;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Dipanggil dari splash_screen.dart untuk cek sesi aktif
  Future<bool> checkSession() async {
    _setLoading(true);
    try {
      _currentUser = await _authService.getCurrentSessionProfile();
      return _currentUser != null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentUser = await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );
      return true;
    } catch (e) {
      _errorMessage = _mapError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentUser = await _authService.login(email: email, password: password);
      return true;
    } catch (e) {
      _errorMessage = _mapError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  /// Dipanggil dari profile_screen.dart setelah pengguna menyimpan perubahan
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentUser = await _authService.updateProfile(
        userId: _currentUser!.id,
        fullName: fullName,
        phone: phone,
        profileImageUrl: profileImageUrl,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui profil: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String _mapError(Object e) {
    final message = e.toString();
    if (message.contains('Invalid login credentials')) {
      return 'Email atau password salah';
    }
    if (message.contains('User already registered')) {
      return 'Email sudah terdaftar';
    }
    return 'Terjadi kesalahan: $message';
  }
}
