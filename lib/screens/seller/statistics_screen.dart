import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/statistics_provider.dart';
import 'best_seller_screen.dart';
import 'peak_hour_screen.dart';

/// 5.3 Statistik Penjualan — halaman ringkasan, dengan pintasan ke
/// menu terlaris (5.4) dan analisis jam ramai (5.5).
class StatisticsScreen extends StatefulWidget {
  final String sellerId;

  const StatisticsScreen({super.key, required this.sellerId});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsProvider>().loadSummary(widget.sellerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistik Penjualan')),
      body: Consumer<StatisticsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.summary == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = provider.summary;

          return RefreshIndicator(
            onRefresh: () => provider.loadSummary(widget.sellerId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.receipt_long_outlined,
                        label: 'Total Pesanan',
                        value: '${summary?.totalOrders ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Produk Terjual',
                        value: '${summary?.totalItemsSold ?? 0}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatCard(
                  icon: Icons.payments_outlined,
                  label: 'Total Transaksi',
                  value: 'Rp ${(summary?.totalTransactionValue ?? 0).toStringAsFixed(0)}',
                  fullWidth: true,
                ),
                const SizedBox(height: 24),
                _NavigationTile(
                  icon: Icons.emoji_events_outlined,
                  title: 'Menu Terlaris',
                  subtitle: 'Lihat urutan produk paling banyak terjual',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BestSellerScreen(sellerId: widget.sellerId),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _NavigationTile(
                  icon: Icons.access_time_outlined,
                  title: 'Analisis Jam Ramai',
                  subtitle: 'Lihat jam dengan transaksi terbanyak',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PeakHourScreen(sellerId: widget.sellerId),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
