import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

// ── Clé prefs ────────────────────────────────────────────
const _kActiveRole = 'active_role';

// ── State —————────────────────────────────────────────────
class AuthState {
  final AppUser? user;
  final UserRole activeRole;
  final bool loading;

  const AuthState({
    this.user,
    this.activeRole = UserRole.client,
    this.loading = false,
});

  AuthState copyWith({
    AppUser? user,
    UserRole? activeRole,
    bool? loading,
}) =>
      AuthState(
        user:      user       ?? this.user,
        activeRole: activeRole ?? this.activeRole,
        loading:   loading    ?? this.loading,
      );
}

// ── Notifier ────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final _client = Supabase.instance.client;

  Future<void> _init() async {
    final session = _client.auth.currentSession;
    if (session == null) return;

    final prefs = await SharedPreferences.getInstance();
    final roleStr = prefs.getString(_kActiveRole) ?? 'client';
    final role = roleStr == 'provider'
        ? UserRole.provider
        : UserRole.client;

    final user = await _fetchUser(session.user.id);
    state = state.copyWith(user: user, activeRole: role);
  }

  // ── Sign in ────────────────────────────────────────────
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(loading: true);

      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = await _fetchUser(res.user!.id);
      state = state.copyWith(user: user, loading: false);
      return null;
    } on AuthException catch (e) {
      state = state.copyWith(loading: false);
      return _mapError(e.message);
    } catch (e) {
      state = state.copyWith(loading: false);
      return 'Une erreur est survenue. Reessayez.';
    }
  }

  // ── Sign up ────────────────────────────────────────────
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(loading: true);

      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (res.user == null) {
        state = state.copyWith(loading: false);
        return 'Inscription échouée. Reessayez.';
      }

      // Creer le profil dans la table profiles
      await _client.from('profiles').insert({
        'id': res.user!.id,
        'full_name': fullName,
        'email': email,
        'role': 'client',
      });

      final user = await _fetchUser(res.user!.id);
      state = state.copyWith(user: user, loading: false);
      return null;
    } on AuthException catch (e) {
      state = state.copyWith(loading: false);
      return _mapError(e.message);
    } catch (e) {
      state = state.copyWith(loading: false);
      return 'Une erreur est survenue. Reessayez.';
    }
  }

  // ── Switch de role ────────────────────────────────────────────
  Future<void> switchRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs
    ,setString(
    _kActiveRole,
    role == UserRole.provider ? 'provider' : 'client',
    );
    state = state.copyWith(activeRole: role);
  }

  // ── Sign out ────────────────────────────────────────────
  Future<void> signOut() async {
    await _client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kActiveRole);
    state = const AuthState();
  }

  // ── Fetch profil Supabase ────────────────────────────────────────────
  Future<AppUser?> _fetchUser(String id) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', id)
          .single();
      return AppUser.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  // ── Traduction erreurs Supabase ────────────────────────────────────────────
  String _mapError(String message) {
    if (message.contains('Invalid login')) {
      return 'Courriel ou mot de passe incorrect.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Veuillez confirmer votre courriel.';
      '
    }
    if (message.contains('already registered')) {
      return 'Ce courriel est déjà utilisé.';
    }
    return message;
  }
}

// ── Providers ────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
    (ref) => AuthNotifier(),
);

final currentUserProvider = Provider<AppUser?>(
    (ref) => ref.watch(authProvider).user,
);

final activeRoleProvider = Provider<UserRole>(
    (ref) => ref.watch(authProvider).activeRole,
);

final isProviderModeProvider = Provider<bool>(
    (ref) => ref.watch(activeRoleProvider) == UserRole.provider,
);


}