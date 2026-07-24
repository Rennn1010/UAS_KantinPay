import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

/// Notifikasi dibuat otomatis oleh trigger database (lihat kantinpay_database_schema.sql
/// bagian 18b & 18c) setiap kali status pesanan/pembayaran berubah. Service ini
/// hanya membaca dan menandai sudah dibaca.
class NotificationService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<NotificationModel>> getNotifications(String userId) async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => NotificationModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  /// Realtime stream — dipakai untuk badge jumlah notifikasi belum dibaca
  /// dan agar notification_screen.dart update otomatis tanpa refresh.
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((row) => NotificationModel.fromMap(row)).toList());
  }
}
