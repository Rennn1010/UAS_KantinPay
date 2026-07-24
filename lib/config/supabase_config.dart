import 'package:supabase_flutter/supabase_flutter.dart';

/// Ganti nilai di bawah ini dengan URL dan anon key project Supabase kamu.
/// Bisa didapat dari Supabase Dashboard -> Project Settings -> API.
class SupabaseConfig {
  static const String supabaseUrl = 'https://igtxfoxabbczqqkkrzux.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlndHhmb3hhYmJjenFxa2tyenV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQxODIzNjIsImV4cCI6MjA5OTc1ODM2Mn0.DszPhtn9NOg2y3Z5QHIeOOTkMb3WLWNs1u5eEZBD7s8';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}

/// Shortcut agar tidak perlu menulis Supabase.instance.client berulang-ulang
final supabase = Supabase.instance.client;
