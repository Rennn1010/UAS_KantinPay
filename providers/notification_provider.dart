import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<NotificationModel>>? _subscription;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Mulai dengarkan notifikasi secara realtime. Dipanggil sekali setelah
  /// login (misalnya dari home_screen.dart / seller_dashboard_screen.dart)
  /// agar badge unread count selalu update di seluruh aplikasi.
  void listenToNotifications(String userId) {
    _subscription?.cancel();
    _setLoading(true);
    _subscription = _service.watchNotifications(userId).listen(
      (list) {
        _notifications = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Gagal memuat notifikasi: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);
      // Realtime stream akan otomatis update _notifications,
      // tapi kita update state lokal dulu agar UI terasa instan.
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final old = _notifications[index];
        _notifications[index] = NotificationModel(
          id: old.id,
          userId: old.userId,
          orderId: old.orderId,
          title: old.title,
          message: old.message,
          isRead: true,
          createdAt: old.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Gagal menandai notifikasi: $e';
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _service.markAllAsRead(userId);
    } catch (e) {
      _errorMessage = 'Gagal menandai semua notifikasi: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
