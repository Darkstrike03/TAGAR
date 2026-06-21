import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  Stream<AuthState> get authStateChanges =>
      Supabase.instance.client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() {
    return Supabase.instance.client.auth.signOut();
  }

  Future<void> sendPasswordReset({required String email}) {
    return Supabase.instance.client.auth.resetPasswordForEmail(email);
  }

  Future<UserData?> getUserData(String userId) async {
    final response = await Supabase.instance.client
        .from('user_data')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (response == null) return null;
    return UserData.fromJson(response);
  }
}
