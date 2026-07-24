import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/statistics_provider.dart';

/// 5.5 Analisis Jam Ramai — menampilkan jumlah transaksi per slot jam ambil
/// dalam bentuk bar chart sederhana, dengan highlight jam paling ramai.
class PeakHourScreen extends StatefulWidget {
  final String sellerId;

  const PeakHourScreen({super.key, required this.sellerId});

  @override
  State<PeakHourScreen> createState() => _PeakHourScreenState();
}

class _PeakHourScreenState extends State<PeakHourScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsProvider>().loadPeakHours(widget.sellerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analisis Jam Ramai')),
      body: Consumer<StatisticsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.peakHours.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.peakHours.isEmpty) {
            return const Center(child: Text('Belum ada data transaksi'));
          }

          final maxCount = provider.peakHours
              .map((e) => e.count)
              .reduce((a, b) => a > b ? a : b);
          final busiest = provider.busiestHour;

          return RefreshIndicator(
            onRefresh: () => provider.loadPeakHours(widget.sellerId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (busiest != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jam Paling Ramai',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${busiest.hourLabel} · ${busiest.count} transaksi',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                ...provider.peakHours.map((item) {
                  final ratio = maxCount > 0 ? item.count / maxCount : 0.0;
                  final isBusiest = item.hourLabel == busiest?.hourLabel;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text(
                            item.hourLabel,
                            style: TextStyle(
                              fontWeight: isBusiest ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 16,
                              backgroundColor: Colors.grey.shade200,
                              color: isBusiest
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.primary.withOpacity(0.4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 32,
                          child: Text('${item.count}', textAlign: TextAlign.end),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
