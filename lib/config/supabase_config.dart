import 'package:supabase_flutter/supabase_flutter.dart';

/// Ganti nilai di bawah ini dengan URL dan anon key project Supabase kamu.
/// Bisa didapat dari Supabase Dashboard -> Project Settings -> API.
class SupabaseConfig {
  static const String supabaseUrl = 'https://igtxfoxabbczqqkkrzux.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_9aRcSkDpqaI2bOiGT9k0pw_LRmk-tn-';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }
}

/// Shortcut agar tidak perlu menulis Supabase.instance.client berulang-ulang
final supabase = Supabase.instance.client;
