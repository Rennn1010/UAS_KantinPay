import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'order_list_screen.dart';
import 'qris_setting_screen.dart';
import 'manage_menu_screen.dart';
import 'manage_category_screen.dart';
import 'statistics_screen.dart';
import '../buyer/profile_screen.dart';
import '../notification_screen.dart';
import '../../providers/notification_provider.dart';

/// Halaman utama sisi penjual. Fungsi lain (kelola menu, statistik, dll)
/// akan ditambahkan sebagai tile baru di sini seiring dibuatnya screen tersebut.
class SellerDashboardScreen extends StatefulWidget {
  final String sellerId;

  const SellerDashboardScreen({super.key, required this.sellerId});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().listenToNotifications(widget.sellerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sellerId = widget.sellerId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Penjual'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifikasi',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationScreen(userId: sellerId),
                    ),
                  ),
                ),
                if (notifProvider.unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${notifProvider.unreadCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: [
          _DashboardTile(
            icon: Icons.receipt_long_outlined,
            label: 'Pesanan Masuk',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderListScreen(sellerId: sellerId),
              ),
            ),
          ),
          _DashboardTile(
            icon: Icons.qr_code_2_outlined,
            label: 'Atur QRIS',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QrisSettingScreen(sellerId: sellerId),
              ),
            ),
          ),
          _DashboardTile(
            icon: Icons.restaurant_menu_outlined,
            label: 'Kelola Menu',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ManageMenuScreen(sellerId: sellerId),
              ),
            ),
          ),
          _DashboardTile(
            icon: Icons.category_outlined,
            label: 'Kelola Kategori',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageCategoryScreen()),
            ),
          ),
          _DashboardTile(
            icon: Icons.bar_chart_outlined,
            label: 'Statistik',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StatisticsScreen(sellerId: sellerId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
