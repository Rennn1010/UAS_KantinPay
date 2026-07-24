import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/statistics_provider.dart';

/// 5.4 Menu Terlaris — urutan produk berdasarkan jumlah penjualan tertinggi
class BestSellerScreen extends StatefulWidget {
  final String sellerId;

  const BestSellerScreen({super.key, required this.sellerId});

  @override
  State<BestSellerScreen> createState() => _BestSellerScreenState();
}

class _BestSellerScreenState extends State<BestSellerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsProvider>().loadBestSellers(widget.sellerId);
    });
  }

  static const List<Color> _medalColors = [
    Color(0xFFFFD700), // emas
    Color(0xFFC0C0C0), // perak
    Color(0xFFCD7F32), // perunggu
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu Terlaris')),
      body: Consumer<StatisticsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.bestSellers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.bestSellers.isEmpty) {
            return const Center(child: Text('Belum ada data penjualan'));
          }

          final maxQty = provider.bestSellers.first.totalQuantity;

          return RefreshIndicator(
            onRefresh: () => provider.loadBestSellers(widget.sellerId),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.bestSellers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = provider.bestSellers[index];
                final ratio = maxQty > 0 ? item.totalQuantity / maxQty : 0.0;
                final medalColor = index < 3 ? _medalColors[index] : null;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: medalColor ?? Colors.grey.shade200,
                          foregroundColor: medalColor != null ? Colors.white : Colors.black87,
                          child: Text('${index + 1}'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.menuName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${item.totalQuantity} terjual',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
