import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/user_model.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map(
    (event) => event.session?.user,
  );
});

final userDataProvider = FutureProvider.family<UserData?, String>((ref, userId) async {
  final response = await Supabase.instance.client
      .from('user_data')
      .select()
      .eq('id', userId)
      .maybeSingle();
  if (response == null) return null;
  return UserData.fromJson(response);
});
