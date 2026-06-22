import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Where the OAuth provider sends the user back. On web → the running app
  // origin (must be in Supabase Auth → Redirect URLs). On mobile → a custom
  // deep-link scheme (must be registered in iOS/Android + Supabase).
  static const _mobileRedirect = 'io.circle12.app://login-callback';
  String get _oauthRedirect => kIsWeb ? '${Uri.base.origin}/' : _mobileRedirect;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      // ?recovery=1 lets the app tell a recovery return apart from an OAuth
      // return (both come back with ?code= under the PKCE flow).
      redirectTo: kIsWeb ? '${Uri.base.origin}/?recovery=1' : null,
    );
  }

  /// Google / Apple via Supabase's OAuth redirect flow. On web this navigates
  /// the page to the provider and back; the auth-state listener then routes the
  /// signed-in user. Provider must be enabled in Supabase → Auth → Providers.
  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _oauthRedirect,
    );
  }

  Future<void> signInWithApple() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: _oauthRedirect,
    );
  }

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
