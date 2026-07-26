import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../screens/buyer/order_tracking_screen.dart';
import '../screens/seller/order_detail_screen.dart';

/// Dipakai baik oleh pembeli maupun penjual. Saat notifikasi terkait
/// pesanan di-tap, diarahkan ke tracking (pembeli) atau detail (penjual)
/// sesuai role yang sedang login.
class NotificationScreen extends StatefulWidget {
  final String userId;

  const NotificationScreen({super.key, required this.userId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().listenToNotifications(widget.userId);
    });
  }

  void _openNotification(NotificationModel notif) {
    if (!notif.isRead) {
      context.read<NotificationProvider>().markAsRead(notif.id);
    }
    if (notif.orderId == null) return;

    final isSeller = context.read<AuthProvider>().isSeller;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                isSeller
                    ? OrderDetailScreen(orderId: notif.orderId!)
                    : OrderTrackingScreen(orderId: notif.orderId!),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed:
                () => context.read<NotificationProvider>().markAllAsRead(
                  widget.userId,
                ),
            child: const Text(
              'Tandai Semua Dibaca',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.notifications.isEmpty) {
            return const Center(child: Text('Belum ada notifikasi'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: provider.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final notif = provider.notifications[index];
              return Card(
                margin: EdgeInsets.zero,
                color:
                    notif.isRead
                        ? null
                        : Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.06),
                child: ListTile(
                  onTap: () => _openNotification(notif),
                  leading: CircleAvatar(
                    backgroundColor:
                        notif.isRead
                            ? Colors.grey.shade200
                            : Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.notifications_outlined,
                      color:
                          notif.isRead
                              ? Colors.grey
                              : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    notif.title,
                    style: TextStyle(
                      fontWeight:
                          notif.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(notif.message),
                      const SizedBox(height: 4),
                      Text(
                        _timeAgo(notif.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing:
                      notif.isRead
                          ? null
                          : Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
