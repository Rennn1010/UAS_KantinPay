import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// Ditampilkan pertama kali saat aplikasi dibuka.
/// Mengecek apakah ada sesi login aktif, lalu mengarahkan ke:
/// - login_screen jika belum login
/// - seller_dashboard_screen jika role penjual
/// - home_screen jika role pembeli
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  Future<void> _checkSession() async {
    // Beri jeda singkat agar logo sempat tampil
    await Future.delayed(const Duration(milliseconds: 800));

    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = await authProvider.checkSession();

    if (!mounted) return;

    if (!isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (authProvider.isSeller) {
      Navigator.pushReplacementNamed(context, '/seller-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_rounded, size: 72, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'KantinPay',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pre-Order & Pembayaran Digital Kantin',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
