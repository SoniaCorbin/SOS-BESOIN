import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/request_model.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// ── Toggle "Actifs / Archivés" pour la liste du client ────
final showArchivedRequestsProvider = StateProvider<bool>((ref) => false);

// ── Provider demandes du client connecté ──────────────────
final myRequestsProvider = FutureProvider<List<RequestModel>>((ref) async {
  ref.watch(authProvider);
  final showArchived = ref.watch(showArchivedRequestsProvider);

  final userId = _client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await _client
      .from('requests')
      .select()
      .eq('client_id', userId)
      .eq('archived_by_client', showArchived)
      .order('created_at', ascending: false);

  return (data as List)
      .map((e) => RequestModel.fromMap(e))
      .toList();
});

// ── Archiver / désarchiver un SOS (côté client) ───────────
Future<void> setRequestArchivedByClient(String requestId, bool archived) async {
  await _client
      .from('requests')
      .update({'archived_by_client': archived})
      .eq('id', requestId);
}

// ── Provider demandes ouvertes (live feed, temps réel) ────
// StreamProvider: l'écran d'accueil prestataire se rafraîchit
// automatiquement dès qu'une nouvelle demande est créée, sans
// action de l'utilisateur (auparavant FutureProvider = un seul
// chargement au montage de l'écran).
final openRequestsProvider = StreamProvider<List<RequestModel>>((ref) {
  final authState = ref.watch(authProvider);

  final userId = _client.auth.currentUser?.id;
  if (userId == null) return Stream.value(<RequestModel>[]);

  // Filtre catégories du prestataire (null/vide = toutes catégories).
  final myCategories = authState.user?.providerCategories;
  final hasCategoryFilter = myCategories != null && myCategories.isNotEmpty;

  // Le realtime Supabase ne permet qu'un seul filtre réseau (.eq) ;
  // l'exclusion des demandes du client, le filtre catégories et le
  // tri/limite se font donc côté client dans le .map().
  return _client
      .from('requests')
      .stream(primaryKey: ['id'])
      .eq('status', 'open')
      .map((rows) {
    final list = rows
        .where((r) => r['client_id'] != userId)
        .where((r) =>
    !hasCategoryFilter || myCategories!.contains(r['category']))
        .map((e) => RequestModel.fromMap(e))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(20).toList();
  });
});
// ── Compteurs "mes demandes" du client (dérivés de myRequestsProvider) ──
class ClientRequestStats {
  final int total;
  final int completed;
  final int inProgress;

  const ClientRequestStats({
    required this.total,
    required this.completed,
    required this.inProgress,
  });
}

final clientRequestStatsProvider = FutureProvider<ClientRequestStats>((ref) async {
  ref.watch(authProvider);

  final userId = _client.auth.currentUser?.id;
  if (userId == null) {
    return const ClientRequestStats(total: 0, completed: 0, inProgress: 0);
  }

  // Indépendant du toggle Actifs/Archivés — les stats reflètent
  // toujours l'ensemble des SOS actifs (non archivés) du client.
  final data = await _client
      .from('requests')
      .select('status')
      .eq('client_id', userId)
      .eq('archived_by_client', false);

  final rows = data as List;
  return ClientRequestStats(
    total:      rows.length,
    completed:  rows.where((r) => r['status'] == 'completed').length,
    inProgress: rows.where((r) => r['status'] == 'in_progress').length,
  );
});

// ── Compteur d'offres en attente sur les demandes du client ────────
// StreamProvider: la RLS 'offers_client_read' limite déjà les lignes
// visibles aux offres sur les demandes du client connecté — pas besoin
// de filtre supplémentaire ici, Supabase s'en charge.
final pendingOffersCountProvider = StreamProvider<int>((ref) {
  ref.watch(authProvider);

  final userId = _client.auth.currentUser?.id;
  if (userId == null) return Stream.value(0);

  return _client
      .from('offers')
      .stream(primaryKey: ['id'])
      .map((rows) => rows.where((o) => o['status'] == 'pending').length);
});

// ── Toggle "Actifs / Archivés" pour la liste du prestataire ────
final showArchivedMissionsProvider = StateProvider<bool>((ref) => false);

final myProviderRequestsProvider = FutureProvider<List<RequestModel>>((ref) async {
  ref.watch(authProvider);
  final showArchived = ref.watch(showArchivedMissionsProvider);

  final userId = _client.auth.currentUser?.id;
  if (userId == null) return [];

  final offersData = await _client
      .from('offers')
      .select('request_id')
      .eq('provider_id', userId);

  final requestIds = (offersData as List)
      .map((o) => o['request_id'] as String)
      .toList();

  if (requestIds.isEmpty) return [];

  final data = await _client
      .from('requests')
      .select()
      .inFilter('id', requestIds)
      .eq('archived_by_provider', showArchived)
      .order('created_at', ascending: false);

  return (data as List)
      .map((e) => RequestModel.fromMap(e))
      .toList();
});

// ── Archiver / désarchiver une mission (côté prestataire) ─
Future<void> setRequestArchivedByProvider(String requestId, bool archived) async {
  await _client
      .from('requests')
      .update({'archived_by_provider': archived})
      .eq('id', requestId);
}

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
    double? latitude,
    double? longitude,
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
        'latitude':     latitude,
        'longitude':    longitude,
      });

      state = const AsyncValue.data(null);
      return null;
    } catch (e) {
      debugPrint('🔴 ERREUR CREATE REQUEST: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return 'Erreur lors de la création. Réessayez.';
    }
  }
}

final requestNotifierProvider =
StateNotifierProvider<RequestNotifier, AsyncValue<void>>(
      (ref) => RequestNotifier(),
);