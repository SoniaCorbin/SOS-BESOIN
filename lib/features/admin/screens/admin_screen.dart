import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

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
    _tabCtrl = TabController(length: 3, vsync: this);
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