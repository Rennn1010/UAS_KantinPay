import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/buyer/home_screen.dart';
import '../screens/buyer/order_tracking_screen.dart';
import '../screens/seller/seller_dashboard_screen.dart';

/// Nama-nama route dikumpulkan di sini agar tidak ada typo string
/// tersebar di berbagai screen ('/home', '/login', dst).
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String sellerDashboard = '/seller-dashboard';
  static const String orderTracking = '/order-tracking';

  /// Route yang tidak butuh argumen tambahan bisa didaftarkan lewat map ini
  /// dan dipasang langsung ke properti `routes` di MaterialApp.
  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),

    // buyerId/sellerId diambil dari sesi yang sedang login,
    // bukan dikirim manual lewat Navigator.
    home: (context) {
      final userId = context.read<AuthProvider>().currentUser!.id;
      return HomeScreen(buyerId: userId);
    },
    sellerDashboard: (context) {
      final userId = context.read<AuthProvider>().currentUser!.id;
      return SellerDashboardScreen(sellerId: userId);
    },

    // Route ini butuh argumen (orderId) yang dikirim lewat
    // Navigator.pushNamed(context, AppRoutes.orderTracking, arguments: orderId)
    orderTracking: (context) {
      final orderId = ModalRoute.of(context)!.settings.arguments as String;
      return OrderTrackingScreen(orderId: orderId);
    },
  };
}
