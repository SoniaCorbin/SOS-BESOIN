import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/request_model.dart';

final _client = Supabase.instance.client;

// ── Provider catégories depuis Supabase ───────────────────
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final data = await _client
      .from('categories')
      .select()
      .eq('is_active', true)
      .order('sort_order');

  return (data as List)
      .map((e) => CategoryModel.fromMap(e))
      .toList();
});

// ── Provider demandes du client connecté ──────────────────
final myRequestsProvider = FutureProvider<List<RequestModel>>((ref) async {
  final userId = _client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await _client
      .from('requests')
      .select()
      .eq('client_id', userId)
      .order('created_at', ascending: false);

  return (data as List)
      .map((e) => RequestModel.fromMap(e))
      .toList();
});

// ── Provider demandes ouvertes (live feed) ────────────────
final openRequestsProvider = FutureProvider<List<RequestModel>>((ref) async {
  final data = await _client
      .from('requests')
      .select()
      .eq('status', 'open')
      .order('created_at', ascending: false)
      .limit(20);

  return (data as List)
      .map((e) => RequestModel.fromMap(e))
      .toList();
});

// ── Notifier pour créer une demande ──────────────────────
class RequestNotifier extends StateNotifier<AsyncValue<void>> {
  RequestNotifier() : super(const AsyncValue.data(null));

  Future<String?> createRequest({
    required String title,
    required String description,
    required String category,
    required String location,
    required String urgency,
    double? budget,
    String? neighborhood,
  }) async {
    try {
      state = const AsyncValue.loading();

      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 'Utilisateur non connecté.';

      await _client.from('requests').insert({
        'client_id':    userId,
        'title':        title,
        'description':  description,
        'category':     category,
        'budget':       budget,
        'location':     location,
        'neighborhood': neighborhood,
        'urgency':      urgency,
        'status':       'open',
      });

      state = const AsyncValue.data(null);
      return null;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return 'Erreur lors de la création. Réessayez.';
    }
  }
}

final requestNotifierProvider =
StateNotifierProvider<RequestNotifier, AsyncValue<void>>(
      (ref) => RequestNotifier(),
);