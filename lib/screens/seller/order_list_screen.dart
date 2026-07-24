import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/seller_order_provider.dart';
import '../../widgets/order_status_badge.dart';
import 'order_detail_screen.dart';

/// Menampilkan semua pesanan masuk milik penjual, dengan tab filter status.
/// Tap salah satu pesanan -> masuk ke order_detail_screen.dart
class OrderListScreen extends StatefulWidget {
  final String sellerId;

  const OrderListScreen({super.key, required this.sellerId});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // null berarti "Semua"
  static const List<OrderStatus?> _tabs = [
    null,
    OrderStatus.menungguVerifikasi,
    OrderStatus.diproses,
    OrderStatus.siapDiambil,
    OrderStatus.selesai,
  ];

  static const List<String> _tabLabels = [
    'Semua',
    'Perlu Verifikasi',
    'Diproses',
    'Siap Diambil',
    'Selesai',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    final status = _tabs[_tabController.index];
    await context
        .read<SellerOrderProvider>()
        .loadOrders(widget.sellerId, filterStatus: status);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Masuk'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: Consumer<SellerOrderProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.orders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.orders.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Belum ada pesanan')),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: provider.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final order = provider.orders[index];
                return _OrderListTile(
                  order: order,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderId: order.id),
                      ),
                    );
                    if (mounted) _loadOrders();
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _OrderListTile extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OrderListTile({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        title: Text(
          order.orderNumber,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Pembeli: ${order.buyerName ?? '-'}'),
            Text('Jam ambil: ${order.pickupTime}'),
            Text('Total: Rp ${order.totalAmount.toStringAsFixed(0)}'),
          ],
        ),
        isThreeLine: true,
        trailing: OrderStatusBadge(status: order.status),
      ),
    );
  }
}
