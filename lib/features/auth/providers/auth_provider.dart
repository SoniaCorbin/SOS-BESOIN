import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

const _kActiveRole = 'active_role';

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
        user:       user       ?? this.user,
        activeRole: activeRole ?? this.activeRole,
        loading:    loading    ?? this.loading,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    init();
  }

  final _client = Supabase.instance.client;

  Future<void> init() async {
    final session = _client.auth.currentSession;
    if (session == null) return;

    final prefs = await SharedPreferences.getInstance();
    final roleStr = prefs.getString(_kActiveRole) ?? 'client';
    final role = roleStr == 'provider'
        ? UserRole.provider
        : UserRole.client;

    final user = await _fetchUser(session.user.id);

    state = const AuthState();
    state = AuthState(user: user, activeRole: role);
  }

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
      return 'Une erreur est survenue. Réessayez.';
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      state = state.copyWith(loading: true);
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
        emailRedirectTo: 'io.sosbesoin://login-callback'
      );
      if (res.user == null) {
        state = state.copyWith(loading: false);
        return 'Inscription échouée. Réessayez.';
      }
      await _client.from('profiles').insert({
        'id':        res.user!.id,
        'full_name': fullName,
        'email':     email,
        'role':      'client',
      });
      final user = await _fetchUser(res.user!.id);
      state = state.copyWith(user: user, loading: false);
      return null;
    } on AuthException catch (e) {
      state = state.copyWith(loading: false);
      return _mapError(e.message);
    } catch (e) {
      print('ERREUR SIGNUP: $e');
      state = state.copyWith(loading: false);
      return 'Une erreur est survenue. Réessayez.';
    }
  }

  Future<void> switchRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kActiveRole,
      role == UserRole.provider ? 'provider' : 'client',
    );
    state = state.copyWith(activeRole: role);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kActiveRole);
    state = const AuthState();
  }

  Future<AppUser?> _fetchUser(String id) async {
    try {
      print('FETCHING USER: $id');
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', id)
          .single();
      print('USER dATA: $data');
      return AppUser.fromMap(data);
    } catch (e) {
      print('FETCH USER ERROR: $e');
      return null;
    }
  }

  String _mapError(String message) {
    if (message.contains('Invalid login')) {
      return 'Courriel ou mot de passe incorrect.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Veuillez confirmer votre courriel.';
    }
    if (message.contains('already registered')) {
      return 'Ce courriel est déjà utilisé.';
    }
    return message;
  }
}

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