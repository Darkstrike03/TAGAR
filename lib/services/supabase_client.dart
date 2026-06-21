import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientService {
  SupabaseClientService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }
}
