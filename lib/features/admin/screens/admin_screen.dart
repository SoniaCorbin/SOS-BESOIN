import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/archive_toggle.dart';

final _client = Supabase.instance.client;

// ── Providers ─────────────────────────────────────────────
final adminUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await _client
      .from('profiles')
      .select()
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data);
});

final adminReportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // 1. Recuperer les signalements
  final data = await _client
      .from('reports')
      .select()
      .order('created_at', ascending: false);

  final reports = List<Map<String, dynamic>>.from(data);

  //2.Pour chaque signalement, recuperer le profil du reporter
  for (int i = 0; i < reports.length; i++) {
    final reporterId = reports[i]['reporter_id'] as String?;
    if (reporterId != null) {
      try {
        final profile = await _client
            .from('profiles')
            .select('full_name, email')
            .eq('id', reporterId)
            .single();
        reports[i] = {...reports[i], 'reporter': profile};
      } catch (_) {
        reports[i] = {...reports[i], 'reporter': null};
      }
    }
  }

  return reports;
});

final adminCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await _client
      .from('categories')
      .select()
      .order('is_custom')
      .order('sort_order');
  return List<Map<String, dynamic>>.from(data);
});

// Supprime une catégorie personnalisée et rebascule les SOS qui
// l'utilisaient vers "Autre" (jamais de SOS orphelin).
Future<void> deleteCustomCategory(String categoryId, String slug) async {
  await _client
      .from('requests')
      .update({'category': 'other'})
      .eq('category', slug);

  await _client.from('categories').delete().eq('id', categoryId);
}

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final users        = await _client.from('profiles').select('id');
  final requests     = await _client.from('requests').select('id');
  final transactions = await _client.from('transactions').select('amount');
  final reports      = await _client.from('reports')
      .select('id').eq('status', 'pending');

  final totalRevenue = (transactions as List).fold<double>(
    0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0) * 0.10,
  );

  return {
    'users':        (users as List).length,
    'requests':     (requests as List).length,
    'revenue':      totalRevenue,
    'pending_reports': (reports as List).length,
  };
});

// ── Screen ────────────────────────────────────────────────
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDim, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Panel Admin',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.amber,
          labelColor: AppColors.amber,
          unselectedLabelColor: AppColors.textMute,
          tabs: const [
            Tab(text: 'Stats'),
            Tab(text: 'Utilisateurs'),
            Tab(text: 'Signalements'),
            Tab(text: 'Waitlist'),
            Tab(text: 'Catégories'),
            Tab(text: 'Litiges'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Stats ──────────────────────────────────
          _StatsTab(statsAsync: statsAsync),
          // ── Utilisateurs ───────────────────────────
          const _UsersTab(),
          // ── Signalements ───────────────────────────
          const _ReportsTab(),
          // — Waitlist ————————————————————————————————
          const _WaitlistTab(),
          // ── Catégories ─────────────────────────────
          const _CategoriesTab(),
          // ── Litiges ────────────────────────────────
          const _LitigesTab(),
        ],
      ),
    );
  }
}

// ── Onglet Stats ──────────────────────────────────────────
class _StatsTab extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> statsAsync;

  const _StatsTab({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      ),
      error: (e, _) => Center(
        child: Text('Erreur: $e',
            style: const TextStyle(color: AppColors.red)),
      ),
      data: (stats) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                _StatCard(
                  icon: Icons.people_rounded,
                  label: 'Utilisateurs',
                  value: '${stats['users']}',
                  color: AppColors.cyan,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'Demandes',
                  value: '${stats['requests']}',
                  color: AppColors.amber,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(
                  icon: Icons.attach_money_rounded,
                  label: 'Revenus plateforme',
                  value: '${(stats['revenue'] as double).toStringAsFixed(0)}\$',
                  color: AppColors.green,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.flag_rounded,
                  label: 'Signalements',
                  value: '${stats['pending_reports']}',
                  color: AppColors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Onglet Utilisateurs ───────────────────────────────────
class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return usersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      ),
      error: (e, _) => Center(
        child: Text('Erreur: $e',
            style: const TextStyle(color: AppColors.red)),
      ),
      data: (users) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, i) {
          final user        = users[i];
          final isSuspended = user['is_suspended'] as bool? ?? false;
          final isAdmin     = user['is_admin'] as bool? ?? false;
          final name        = user['full_name'] as String? ?? 'Sans nom';
          final email       = user['email'] as String? ?? '';
          final createdAt   = user['created_at'] != null
              ? DateTime.parse(user['created_at'] as String)
              : DateTime.now();

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSuspended
                  ? AppColors.redSoft
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSuspended
                    ? AppColors.red
                    : AppColors.line2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAdmin
                        ? AppColors.amberSoft
                        : AppColors.surface2,
                    border: Border.all(
                      color: isAdmin
                          ? AppColors.amber
                          : AppColors.line2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty
                          ? name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isAdmin
                            ? AppColors.amber
                            : AppColors.text,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.amberSoft,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.amber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMute,
                        ),
                      ),
                      Text(
                        DateFormat('d MMM yyyy', 'fr_CA')
                            .format(createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMute,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bouton suspendre/réactiver
                if (!isAdmin)
                  IconButton(
                    onPressed: () => _toggleSuspend(
                      context, ref,
                      user['id'] as String,
                      isSuspended,
                    ),
                    icon: Icon(
                      isSuspended
                          ? Icons.check_circle_outline_rounded
                          : Icons.block_rounded,
                      color: isSuspended
                          ? AppColors.green
                          : AppColors.red,
                      size: 22,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleSuspend(
      BuildContext context,
      WidgetRef ref,
      String userId,
      bool isSuspended,
      ) async {
    await _client.from('profiles').update({
      'is_suspended': !isSuspended,
    }).eq('id', userId);

    ref.refresh(adminUsersProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSuspended
              ? '✅ Compte réactivé'
              : '🚫 Compte suspendu'),
          backgroundColor: isSuspended
              ? AppColors.green
              : AppColors.red,
        ),
      );
    }
  }
}

// ── Onglet Signalements ───────────────────────────────────
class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(adminReportsProvider);

    return reportsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      ),
      error: (e, _) => Center(
        child: Text('Erreur: $e',
            style: const TextStyle(color: AppColors.red)),
      ),
      data: (reports) => reports.isEmpty
          ? const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined,
                size: 48, color: AppColors.textMute),
            SizedBox(height: 16),
            Text(
              'Aucun signalement',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDim,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, i) {
          final report    = reports[i];
          final reason    = report['reason'] as String? ?? '';
          final status    = report['status'] as String? ?? 'pending';
          final desc      = report['description'] as String?;
          final createdAt = report['created_at'] != null
              ? DateTime.parse(report['created_at'] as String)
              : DateTime.now();
          final reporter  = report['reporter'] as Map<String, dynamic>?;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: status == 'pending'
                    ? AppColors.red
                    : AppColors.line2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag_rounded,
                        size: 16, color: AppColors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'pending'
                            ? AppColors.redSoft
                            : AppColors.greenSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status == 'pending'
                            ? 'En attente'
                            : 'Résolu',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: status == 'pending'
                              ? AppColors.red
                              : AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                if (desc != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Par: ${reporter?['full_name'] ?? 'Inconnu'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMute,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('d MMM yyyy', 'fr_CA')
                          .format(createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMute,
                      ),
                    ),
                  ],
                ),
                if (status == 'pending') ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () => _resolveReport(
                        context, ref,
                        report['id'] as String,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.green,
                        side: const BorderSide(
                            color: AppColors.green),
                      ),
                      child: const Text(
                        'Marquer comme résolu',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _resolveReport(
      BuildContext context,
      WidgetRef ref,
      String reportId,
      ) async {
    await _client.from('reports').update({
      'status':      'resolved',
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);

    ref.refresh(adminReportsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Signalement résolu'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }
}

// ── Stat card ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Provider waitlist ─────────────────────────────────────
final adminWaitlistProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await _client
      .from('waitlist')
      .select()
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data);
});

// ── Onglet Waitlist ───────────────────────────────────────
class _WaitlistTab extends ConsumerWidget {
  const _WaitlistTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waitlistAsync = ref.watch(adminWaitlistProvider);

    return waitlistAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      ),
      error: (e, _) => Center(
        child: Text('Erreur: $e',
            style: const TextStyle(color: AppColors.red)),
      ),
      data: (waitlist) => waitlist.isEmpty
          ? const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 48, color: AppColors.textMute),
            SizedBox(height: 16),
            Text(
              'Aucune inscription pour l\'instant',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDim,
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Compteur
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.amber),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_rounded,
                    color: AppColors.amber, size: 24),
                const SizedBox(width: 12),
                Text(
                  '${waitlist.length} inscrit${waitlist.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amber,
                  ),
                ),
                const Spacer(),
                Text(
                  '${waitlist.where((w) => w['role'] == 'prestataire').length} pros · ${waitlist.where((w) => w['role'] == 'client').length} clients',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
          ),
          // Liste
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: waitlist.length,
              itemBuilder: (context, i) {
                final w          = waitlist[i];
                final name       = w['name'] as String? ?? 'Sans nom';
                final email      = w['email'] as String? ?? '';
                final role       = w['role'] as String? ?? 'client';
                final createdAt  = w['created_at'] != null
                    ? DateTime.parse(w['created_at'] as String)
                    : DateTime.now();
                final isProvider = role == 'prestataire';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isProvider
                              ? AppColors.cyanSoft
                              : AppColors.amberSoft,
                          border: Border.all(
                            color: isProvider
                                ? AppColors.cyan
                                : AppColors.amber,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isProvider
                                  ? AppColors.cyan
                                  : AppColors.amber,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMute,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isProvider
                                  ? AppColors.cyanSoft
                                  : AppColors.amberSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isProvider ? 'Pro' : 'Client',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isProvider
                                    ? AppColors.cyan
                                    : AppColors.amber,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d MMM', 'fr_CA')
                                .format(createdAt),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMute,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Onglet Catégories ─────────────────────────────────────
class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return categoriesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      ),
      error: (e, _) => Center(
        child: Text('Erreur: $e',
            style: const TextStyle(color: AppColors.red)),
      ),
      data: (categories) {
        final baseCats = categories.where((c) => c['is_custom'] != true).toList();
        final customCats = categories.where((c) => c['is_custom'] == true).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Catégories de base (${baseCats.length})',
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ne peuvent pas être supprimées.',
              style: TextStyle(fontSize: 12, color: AppColors.textMute),
            ),
            const SizedBox(height: 12),
            ...baseCats.map((cat) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line2),
              ),
              child: Row(
                children: [
                  Text(cat['emoji'] as String? ?? '🏷️',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cat['label'] as String? ?? cat['slug'] as String,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.text),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 24),
            Text(
              'Catégories ajoutées par les utilisateurs (${customCats.length})',
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            if (customCats.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line2),
                ),
                child: const Center(
                  child: Text(
                    'Aucune catégorie personnalisée pour l\'instant.',
                    style: TextStyle(color: AppColors.textMute, fontSize: 13),
                  ),
                ),
              )
            else
              ...customCats.map((cat) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line2),
                ),
                child: Row(
                  children: [
                    Text(cat['emoji'] as String? ?? '🏷️',
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat['label'] as String? ?? cat['slug'] as String,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.text),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _confirmDelete(
                        context, ref,
                        cat['id'] as String,
                        cat['slug'] as String,
                        cat['label'] as String? ?? cat['slug'] as String,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.red, size: 20),
                    ),
                  ],
                ),
              )),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
      String categoryId, String slug, String label) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Supprimer "$label" ?',
          style: const TextStyle(
              color: AppColors.text, fontFamily: 'SpaceGrotesk'),
        ),
        content: const Text(
          'Les SOS existants avec cette catégorie seront rebasculés vers "Autre". Cette action est irréversible.',
          style: TextStyle(color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textMute)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Oui, supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await deleteCustomCategory(categoryId, slug);
      ref.invalidate(adminCategoriesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catégorie supprimée.'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}


// ══════════════════════════════════════════════════════════
// ── ONGLET LITIGES ───────────────────────────────────────
// ══════════════════════════════════════════════════════════

// SOS complétés/en cours avec leur prestataire jumelé
final adminCompletedRequestsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await _client
      .from('requests')
      .select()
      .inFilter('status', ['completed', 'in_progress'])
      .order('created_at', ascending: false);

  final requests = List<Map<String, dynamic>>.from(data);

  for (int i = 0; i < requests.length; i++) {
    final clientId = requests[i]['client_id'] as String?;
    if (clientId != null) {
      try {
        final profile = await _client
            .from('profiles')
            .select('full_name')
            .eq('id', clientId)
            .single();
        requests[i] = {...requests[i], 'client_name': profile['full_name']};
      } catch (_) {
        requests[i] = {...requests[i], 'client_name': 'Inconnu'};
      }
    }

    try {
      final offer = await _client
          .from('offers')
          .select('id, provider_id')
          .eq('request_id', requests[i]['id'] as String)
          .inFilter('status', ['accepted', 'completed'])
          .limit(1)
          .maybeSingle();

      if (offer != null) {
        final provProfile = await _client
            .from('profiles')
            .select('full_name')
            .eq('id', offer['provider_id'] as String)
            .single();
        requests[i] = {
          ...requests[i],
          'provider_name': provProfile['full_name'],
          'offer_id': offer['id'] as String,
        };
      } else {
        requests[i] = {...requests[i], 'provider_name': '—'};
      }
    } catch (_) {
      requests[i] = {...requests[i], 'provider_name': '—'};
    }
  }

  return requests;
});

// Litiges
final adminLitigesProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await _client
      .from('litiges')
      .select()
      .order('created_at', ascending: false);

  final litiges = List<Map<String, dynamic>>.from(data);

  for (int i = 0; i < litiges.length; i++) {
    final requestId = litiges[i]['request_id'] as String?;
    if (requestId != null) {
      try {
        final req = await _client
            .from('requests')
            .select('title, category, status')
            .eq('id', requestId)
            .single();
        litiges[i] = {...litiges[i], 'request': req};
      } catch (_) {}
    }
  }

  return litiges;
});

Future<void> createLitige({
  required String requestId,
  String? offerId,
  required String reason,
  required String description,
}) async {
  await _client.from('litiges').insert({
    'request_id':  requestId,
    'offer_id':    offerId,
    'opened_by':   _client.auth.currentUser?.id,
    'reason':      reason,
    'description': description,
    'status':      'open',
  });
}

Future<void> resolveLitige(String litigeId) async {
  await _client.from('litiges').update({
    'status':      'resolved',
    'resolved_at': DateTime.now().toIso8601String(),
  }).eq('id', litigeId);
}

class _LitigesTab extends ConsumerWidget {
  const _LitigesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final litigesAsync = ref.watch(adminLitigesProvider);
    final requestsAsync = ref.watch(adminCompletedRequestsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Litiges en cours',
            style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 18,
                fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 12),
        litigesAsync.when(
          loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2))),
          error: (e, _) => Text('Erreur: $e', style: const TextStyle(color: AppColors.red)),
          data: (litiges) {
            final openL = litiges.where((l) => l['status'] == 'open').toList();
            final resolvedL = litiges.where((l) => l['status'] == 'resolved').toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (openL.isEmpty)
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line2)),
                    child: const Center(child: Text('Aucun litige en cours.',
                        style: TextStyle(color: AppColors.textMute, fontSize: 13))),
                  )
                else
                  ...openL.map((l) => _LitigeCard(litige: l, onResolved: () => ref.invalidate(adminLitigesProvider))),
                if (resolvedL.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Résolus (${resolvedL.length})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMute)),
                  const SizedBox(height: 8),
                  ...resolvedL.map((l) => _LitigeCard(litige: l, onResolved: () => ref.invalidate(adminLitigesProvider))),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        const Divider(color: AppColors.line),
        const SizedBox(height: 16),
        const Text('SOS complétés',
            style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 18,
                fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 4),
        const Text('Missions terminées ou en cours avec un prestataire jumelé.',
            style: TextStyle(fontSize: 12, color: AppColors.textMute)),
        const SizedBox(height: 12),
        requestsAsync.when(
          loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2))),
          error: (e, _) => Text('Erreur: $e', style: const TextStyle(color: AppColors.red)),
          data: (requests) {
            if (requests.isEmpty) {
              return Container(
                width: double.infinity, padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line2)),
                child: const Center(child: Text('Aucun SOS complété.',
                    style: TextStyle(color: AppColors.textMute, fontSize: 13))),
              );
            }
            return Column(children: requests.map((r) => _CompletedSOSCard(
                request: r, onLitigeOpened: () => ref.invalidate(adminLitigesProvider))).toList());
          },
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _CompletedSOSCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onLitigeOpened;
  const _CompletedSOSCard({required this.request, required this.onLitigeOpened});

  @override
  Widget build(BuildContext context) {
    final title = request['title'] as String? ?? '—';
    final category = (request['category'] as String? ?? '').toUpperCase();
    final status = request['status'] as String? ?? '';
    final clientName = request['client_name'] as String? ?? 'Inconnu';
    final providerName = request['provider_name'] as String? ?? '—';
    final createdAt = request['created_at'] != null ? DateTime.tryParse(request['created_at'] as String) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.amberSoft, borderRadius: BorderRadius.circular(6)),
              child: Text(category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.amber))),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: status == 'completed' ? AppColors.greenSoft : AppColors.cyanSoft, borderRadius: BorderRadius.circular(6)),
              child: Text(status == 'completed' ? 'Complété' : 'En cours',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: status == 'completed' ? AppColors.green : AppColors.cyan))),
        ]),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textMute),
          const SizedBox(width: 4),
          Text('Client: $clientName', style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
          const SizedBox(width: 16),
          const Icon(Icons.handyman_rounded, size: 13, color: AppColors.textMute),
          const SizedBox(width: 4),
          Expanded(child: Text('Pro: $providerName', style: const TextStyle(fontSize: 12, color: AppColors.textDim), overflow: TextOverflow.ellipsis)),
        ]),
        if (createdAt != null) ...[
          const SizedBox(height: 4),
          Text(timeago.format(createdAt, locale: 'fr'), style: const TextStyle(fontSize: 11, color: AppColors.textMute)),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
              onPressed: () => _openDetail(context),
              icon: const Icon(Icons.visibility_outlined, size: 15),
              label: const Text('Voir le détail'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.cyan, side: const BorderSide(color: AppColors.cyan)))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
              onPressed: () => _openLitigeForm(context),
              icon: const Icon(Icons.gavel_rounded, size: 15),
              label: const Text('Ouvrir un litige'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red)))),
        ]),
      ]),
    );
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SOSDetailSheet(requestId: request['id'] as String),
    );
  }

  void _openLitigeForm(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _OpenLitigeSheet(
            requestId: request['id'] as String, offerId: request['offer_id'] as String?,
            requestTitle: request['title'] as String? ?? '—',
            onCreated: () { Navigator.pop(context); onLitigeOpened(); }));
  }
}

class _OpenLitigeSheet extends StatefulWidget {
  final String requestId;
  final String? offerId;
  final String requestTitle;
  final VoidCallback onCreated;
  const _OpenLitigeSheet({required this.requestId, this.offerId, required this.requestTitle, required this.onCreated});

  @override
  State<_OpenLitigeSheet> createState() => _OpenLitigeSheetState();
}

class _OpenLitigeSheetState extends State<_OpenLitigeSheet> {
  String _reason = 'plainte_client';
  final _descCtrl = TextEditingController();
  bool _loading = false;

  static const _reasons = [
    {'id': 'plainte_client', 'label': 'Plainte du client'},
    {'id': 'plainte_prestataire', 'label': 'Plainte du prestataire'},
    {'id': 'remboursement', 'label': 'Demande de remboursement'},
    {'id': 'qualite', 'label': 'Qualité du service'},
    {'id': 'no_show', 'label': 'Prestataire absent (no-show)'},
    {'id': 'autre', 'label': 'Autre'},
  ];

  @override
  void dispose() { _descCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez décrire le problème.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await createLitige(requestId: widget.requestId, offerId: widget.offerId, reason: _reason, description: _descCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Litige ouvert.'), backgroundColor: AppColors.green));
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(child: Container(padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line2, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Ouvrir un litige', style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.text)),
            const SizedBox(height: 8),
            Text('SOS: ${widget.requestTitle}', style: const TextStyle(fontSize: 13, color: AppColors.textDim)),
            const SizedBox(height: 20),
            const Text('Raison', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDim)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _reason, dropdownColor: AppColors.surface2,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.amber),
              style: const TextStyle(color: AppColors.text, fontSize: 14),
              decoration: InputDecoration(filled: true, fillColor: AppColors.surface2, isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line2)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line2)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.amber, width: 1.5))),
              items: _reasons.map((r) => DropdownMenuItem(value: r['id'], child: Text(r['label']!))).toList(),
              onChanged: (v) { if (v != null) setState(() => _reason = v); },
            ),
            const SizedBox(height: 16),
            const Text('Description du problème', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDim)),
            const SizedBox(height: 8),
            TextField(controller: _descCtrl, style: const TextStyle(color: AppColors.text), maxLines: 4,
                decoration: InputDecoration(hintText: 'Décrivez le problème en détail...', hintStyle: const TextStyle(color: AppColors.textMute),
                    alignLabelWithHint: true, filled: true, fillColor: AppColors.surface2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line2)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line2)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.amber, width: 1.5)))),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                    : const Text('Confirmer l\'ouverture'))),
            const SizedBox(height: 8),
          ]))),
    );
  }
}

class _LitigeCard extends StatelessWidget {
  final Map<String, dynamic> litige;
  final VoidCallback onResolved;
  const _LitigeCard({required this.litige, required this.onResolved});

  @override
  Widget build(BuildContext context) {
    final reason = litige['reason'] as String? ?? '';
    final description = litige['description'] as String? ?? '';
    final status = litige['status'] as String? ?? 'open';
    final isOpen = status == 'open';
    final createdAt = litige['created_at'] != null ? DateTime.tryParse(litige['created_at'] as String) : null;
    final resolvedAt = litige['resolved_at'] != null ? DateTime.tryParse(litige['resolved_at'] as String) : null;
    final req = litige['request'] as Map<String, dynamic>?;
    final reqTitle = req?['title'] as String? ?? '—';

    String reasonLabel;
    switch (reason) {
      case 'plainte_client': reasonLabel = 'Plainte client'; break;
      case 'plainte_prestataire': reasonLabel = 'Plainte prestataire'; break;
      case 'remboursement': reasonLabel = 'Remboursement'; break;
      case 'qualite': reasonLabel = 'Qualité'; break;
      case 'no_show': reasonLabel = 'No-show'; break;
      default: reasonLabel = 'Autre'; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: isOpen ? const Color(0x14EF4444) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isOpen ? AppColors.red : AppColors.line2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: isOpen ? const Color(0x26EF4444) : AppColors.greenSoft, borderRadius: BorderRadius.circular(6)),
              child: Text(isOpen ? '● Ouvert' : '✓ Résolu',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isOpen ? AppColors.red : AppColors.green))),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(6)),
              child: Text(reasonLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textDim))),
          const Spacer(),
          if (createdAt != null) Text(timeago.format(createdAt, locale: 'fr'), style: const TextStyle(fontSize: 11, color: AppColors.textMute)),
        ]),
        const SizedBox(height: 10),
        Text('SOS: $reqTitle', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
        const SizedBox(height: 6),
        Text(description, style: const TextStyle(fontSize: 13, color: AppColors.textDim, height: 1.5)),
        if (resolvedAt != null) ...[
          const SizedBox(height: 6),
          Text('Résolu ${timeago.format(resolvedAt, locale: 'fr')}',
              style: const TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w500)),
        ],
        if (isOpen) ...[
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: () => _resolveDialog(context),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: const Text('Marquer comme résolu'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.bg))),
        ],
      ]),
    );
  }

  Future<void> _resolveDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(backgroundColor: AppColors.surface,
            title: const Text('Résoudre ce litige ?', style: TextStyle(color: AppColors.text, fontFamily: 'SpaceGrotesk')),
            content: const Text('Ce litige sera marqué comme résolu. Cette action est irréversible.', style: TextStyle(color: AppColors.textDim)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler', style: TextStyle(color: AppColors.textMute))),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.green), child: const Text('Oui, résoudre')),
            ]));
    if (confirm != true) return;
    try {
      await resolveLitige(litige['id'] as String);
      onResolved();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Litige résolu.'), backgroundColor: AppColors.green));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }
}

// ── Bottom sheet détail complet d'un SOS (admin) ──────────
class _SOSDetailSheet extends StatefulWidget {
  final String requestId;
  const _SOSDetailSheet({required this.requestId});

  @override
  State<_SOSDetailSheet> createState() => _SOSDetailSheetState();
}

class _SOSDetailSheetState extends State<_SOSDetailSheet> {
  Map<String, dynamic>? request;
  List<Map<String, dynamic>> offers = [];
  Map<String, dynamic>? invoice;
  List<Map<String, dynamic>> messages = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Request
    final reqData = await _client
        .from('requests')
        .select()
        .eq('id', widget.requestId)
        .single();

    // Client name
    String clientName = 'Inconnu';
    try {
      final cp = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', reqData['client_id'] as String)
          .single();
      clientName = cp['full_name'] as String? ?? 'Inconnu';
    } catch (_) {}

    request = {...reqData, 'client_name': clientName};

    // Offers
    final offersData = await _client
        .from('offers')
        .select()
        .eq('request_id', widget.requestId)
        .order('created_at', ascending: false);

    final enrichedOffers = <Map<String, dynamic>>[];
    for (final offer in List<Map<String, dynamic>>.from(offersData)) {
      final providerId = offer['provider_id'] as String?;
      if (providerId != null) {
        try {
          final profile = await _client
              .from('profiles')
              .select('full_name')
              .eq('id', providerId)
              .single();
          enrichedOffers.add({...offer, 'profiles': profile});
        } catch (_) {
          enrichedOffers.add({...offer, 'profiles': null});
        }
      } else {
        enrichedOffers.add(offer);
      }
    }
    offers = enrichedOffers;

    // Invoice
    final invData = await _client
        .from('invoices')
        .select()
        .eq('request_id', widget.requestId)
        .maybeSingle();
    invoice = invData;

    // Messages
    final offerIds = offers.map((o) => o['id'] as String).toList();
    if (offerIds.isNotEmpty) {
      final msgsData = await _client
          .from('messages')
          .select()
          .inFilter('offer_id', offerIds)
          .order('created_at');

      final enrichedMsgs = <Map<String, dynamic>>[];
      for (final msg in List<Map<String, dynamic>>.from(msgsData)) {
        final senderId = msg['sender_id'] as String?;
        if (senderId != null) {
          try {
            final profile = await _client
                .from('profiles')
                .select('full_name')
                .eq('id', senderId)
                .single();
            enrichedMsgs.add({...msg, 'profiles': profile});
          } catch (_) {
            enrichedMsgs.add({...msg, 'profiles': null});
          }
        } else {
          enrichedMsgs.add(msg);
        }
      }
      messages = enrichedMsgs;
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
            : ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.line2, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),

            // ── Détail du SOS ──
            const Text('Détail du SOS', style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 16),
            _DetailRow(label: 'Titre', value: request?['title'] as String? ?? '—'),
            _DetailRow(label: 'Client', value: request?['client_name'] as String? ?? '—'),
            _DetailRow(label: 'Catégorie', value: request?['category'] as String? ?? '—'),
            _DetailRow(label: 'Statut', value: request?['status'] as String? ?? '—'),
            _DetailRow(label: 'Lieu', value: request?['location'] as String? ?? '—'),
            _DetailRow(label: 'Urgence', value: request?['urgency'] as String? ?? '—'),
            if (request?['budget'] != null)
              _DetailRow(label: 'Budget', value: '${request!['budget']}\$'),
            _DetailRow(label: 'Description', value: request?['description'] as String? ?? '—'),
            const SizedBox(height: 24),

            // ── Offres ──
            Text('Offres (${offers.length})', style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 10),
            if (offers.isEmpty)
              const Text('Aucune offre.', style: TextStyle(fontSize: 13, color: AppColors.textMute))
            else
              ...offers.map((offer) {
                final provName = (offer['profiles'] as Map<String, dynamic>?)?['full_name'] as String? ?? '—';
                final status = offer['status'] as String? ?? '';
                final statusColor = status == 'accepted' || status == 'completed' ? AppColors.green : AppColors.textMute;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: status == 'accepted' || status == 'completed' ? AppColors.greenSoft : AppColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(provName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                      Text('${offer['price']}\$', style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.amber)),
                    ]),
                    const SizedBox(height: 4),
                    Text(offer['message'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                      const SizedBox(width: 8),
                      Text('🕐 ${offer['availability'] ?? ''}', style: const TextStyle(fontSize: 11, color: AppColors.textMute)),
                    ]),
                  ]),
                );
              }),
            const SizedBox(height: 24),

            // ── Facture ──
            const Text('Facture', style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 10),
            if (invoice == null)
              const Text('Aucune facture.', style: TextStyle(fontSize: 13, color: AppColors.textMute))
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line2)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _DetailRow(label: 'Numéro', value: '#${invoice!['invoice_number'] ?? '—'}'),
                  _DetailRow(label: 'Montant', value: '${invoice!['amount'] ?? 0}\$'),
                  _DetailRow(label: 'Prestataire', value: '${invoice!['provider_amount'] ?? 0}\$'),
                  _DetailRow(label: 'Statut', value: invoice!['status'] as String? ?? '—'),
                ]),
              ),
            const SizedBox(height: 24),

            // ── Messages ──
            Text('Messages (${messages.length})', style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 10),
            if (messages.isEmpty)
              const Text('Aucun message.', style: TextStyle(fontSize: 13, color: AppColors.textMute))
            else
              ...messages.map((msg) {
                final senderName = (msg['profiles'] as Map<String, dynamic>?)?['full_name'] as String? ?? '—';
                final content = msg['content'] as String? ?? '';
                final createdAt = msg['created_at'] != null ? DateTime.tryParse(msg['created_at'] as String) : null;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(8)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(senderName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.cyan)),
                      if (createdAt != null)
                        Text(timeago.format(createdAt, locale: 'fr'), style: const TextStyle(fontSize: 10, color: AppColors.textMute)),
                    ]),
                    const SizedBox(height: 4),
                    Text(content, style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.4)),
                  ]),
                );
              }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMute))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: AppColors.text))),
        ],
      ),
    );
  }
}