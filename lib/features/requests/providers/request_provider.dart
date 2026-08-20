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

// ── Trouver ou créer une catégorie personnalisée ──────────
// Utilisé quand un utilisateur choisit "Autre" et tape un nouveau nom.
// Vérifie d'abord si une catégorie similaire existe déjà (insensible à
// la casse) pour éviter les doublons ("Plomberie" / "plomberie ").
String _slugifyLabel(String label) {
  var s = label.trim().toLowerCase()
      .replaceAll(RegExp(r'[àáâãäå]'), 'a')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôõö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return s.isEmpty ? 'autre-${DateTime.now().millisecondsSinceEpoch}' : s;
}

Future<String> findOrCreateCategory(String label) async {
  final trimmed = label.trim();
  if (trimmed.isEmpty) return 'other';

  final existing = await _client
      .from('categories')
      .select('slug')
      .ilike('label', trimmed)
      .maybeSingle();
  if (existing != null) return existing['slug'] as String;

  final baseSlug = _slugifyLabel(trimmed);
  var slug = baseSlug;
  var suffix = 0;
  while (true) {
    final clash = await _client
        .from('categories')
        .select('slug')
        .eq('slug', slug)
        .maybeSingle();
    if (clash == null) break;
    suffix++;
    slug = '$baseSlug-$suffix';
  }

  await _client.from('categories').insert({
    'slug':       slug,
    'label':      trimmed,
    'emoji':      '🏷️',
    'is_active':  true,
    'is_custom':  true,
    'sort_order': 999,
  });

  return slug;
}

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

// StreamProvider: la liste "Mes missions" du prestataire se met à jour en
// temps réel (ex: le client valide la mission -> statut 'completed') sans
// qu'il ait besoin de rafraîchir sa page. Le flux écoute ses propres
// offres (colonne 'status' incluse) et recharge les 'requests' liées à
// chaque changement.
// (auparavant FutureProvider = un seul chargement au montage de l'écran)
final myProviderRequestsProvider = StreamProvider<List<RequestModel>>((ref) {
  ref.watch(authProvider);
  final showArchived = ref.watch(showArchivedMissionsProvider);

  final userId = _client.auth.currentUser?.id;
  if (userId == null) return Stream.value(<RequestModel>[]);

  return _client
      .from('offers')
      .stream(primaryKey: ['id'])
      .eq('provider_id', userId)
      .asyncMap((offersData) async {
    final requestIds = offersData
        .map((o) => o['request_id'] as String)
        .toList();

    if (requestIds.isEmpty) return <RequestModel>[];

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
      state = AsyncValue.error(e, StackTrace.current);
      return 'Erreur lors de la création. Réessayez.';
    }
  }
}

final requestNotifierProvider =
StateNotifierProvider<RequestNotifier, AsyncValue<void>>(
      (ref) => RequestNotifier(),
);