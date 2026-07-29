import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/archive_toggle.dart';

final _client = Supabase.instance.client;

// ── Déclencheur Realtime ──────────────────────────────────
// Ce provider écoute les changements sur les tables clés et incrémente un compteur.
// En le "watchant" dans nos FutureProviders, ils se rafraîchiront automatiquement.
final adminRealtimeTriggerProvider = StreamProvider<int>((ref) {
  final controller = StreamController<int>.broadcast();
  int count = 0;

  final channel = _client.channel('admin-db-changes');

  void notify() {
    count++;
    if (!controller.isClosed) controller.add(count);
  }

  channel
      .onPostgresChanges(schema: 'public', table: 'profiles',     event: PostgresChangeEvent.all, callback: (_) => notify())
      .onPostgresChanges(schema: 'public', table: 'requests',     event: PostgresChangeEvent.all, callback: (_) => notify())
      .onPostgresChanges(schema: 'public', table: 'transactions', event: PostgresChangeEvent.all, callback: (_) => notify())
      .onPostgresChanges(schema: 'public', table: 'reports',      event: PostgresChangeEvent.all, callback: (_) => notify())
      .onPostgresChanges(schema: 'public', table: 'waitlist',     event: PostgresChangeEvent.all, callback: (_) => notify())
      .onPostgresChanges(schema: 'public', table: 'categories',   event: PostgresChangeEvent.all, callback: (_) => notify())
      .onPostgresChanges(schema: 'public', table: 'messages',     event: PostgresChangeEvent.all, callback: (_) => notify())
      .onPostgresChanges(schema: 'public', table: 'offers',       event: PostgresChangeEvent.all, callback: (_) => notify())
      .onPostgresChanges(schema: 'public', table: 'invoices',     event: PostgresChangeEvent.all, callback: (_) => notify())
      .subscribe();

  ref.onDispose(() {
    _client.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});

// ── Providers ─────────────────────────────────────────────
final adminUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(adminRealtimeTriggerProvider);
  final data = await _client
      .from('profiles')
      .select()
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data);
});

final adminReportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(adminRealtimeTriggerProvider);
  final data = await _client
      .from('reports')
      .select()
      .order('created_at', ascending: false);

  final reports = List<Map<String, dynamic>>.from(data);

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
  ref.watch(adminRealtimeTriggerProvider);
  final data = await _client
      .from('categories')
      .select()
      .order('is_custom')
      .order('sort_order');
  return List<Map<String, dynamic>>.from(data);
});

Future<void> deleteCustomCategory(String categoryId, String slug) async {
  await _client
      .from('requests')
      .update({'category': 'other'})
      .eq('category', slug);

  await _client.from('categories').delete().eq('id', categoryId);
}

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(adminRealtimeTriggerProvider);
  final now = DateTime.now();

  final users        = await _client.from('profiles').select('id');
  final requests     = await _client.from('requests').select('id');
  final transactions = await _client.from('transactions').select('amount, created_at');
  final reports      = await _client.from('reports')
      .select('id').eq('status', 'pending');

  final txList = List<Map<String, dynamic>>.from(transactions as List);
  final totalRevenue = txList.fold<double>(
    0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0) * 0.10,
  );

  // Données pour le graphique (7 derniers jours)
  final Map<String, double> revenueByDay = {};
  for (int i = 0; i < 7; i++) {
    final date = now.subtract(Duration(days: i));
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    revenueByDay[dateStr] = 0;
  }

  for (final tx in txList) {
    final txDate = DateTime.parse(tx['created_at'] as String);
    final dateStr = DateFormat('yyyy-MM-dd').format(txDate);
    if (revenueByDay.containsKey(dateStr)) {
      revenueByDay[dateStr] = revenueByDay[dateStr]! + ((tx['amount'] as num?)?.toDouble() ?? 0) * 0.10;
    }
  }

  final sortedDates = revenueByDay.keys.toList()..sort();
  final List<FlSpot> revenueSpots = [];
  for (int i = 0; i < sortedDates.length; i++) {
    revenueSpots.add(FlSpot(i.toDouble(), revenueByDay[sortedDates[i]]!));
  }

  // Activité récente
  final recentUsers = await _client.from('profiles').select('full_name, created_at').order('created_at', ascending: false).limit(3);
  final recentRequests = await _client.from('requests').select('title, created_at').order('created_at', ascending: false).limit(3);
  final recentTransactions = await _client.from('transactions').select('amount, created_at').order('created_at', ascending: false).limit(3);

  final List<Map<String, dynamic>> activity = [];
  for (var u in (recentUsers as List)) {
    activity.add({'type': 'user', 'title': 'Nouvel utilisateur : ${u['full_name']}', 'date': u['created_at']});
  }
  for (var r in (recentRequests as List)) {
    activity.add({'type': 'request', 'title': 'Nouveau SOS : ${r['title']}', 'date': r['created_at']});
  }
  for (var t in (recentTransactions as List)) {
    activity.add({'type': 'transaction', 'title': 'Paiement reçu : ${((t['amount'] as num).toDouble() * 0.1).toStringAsFixed(2)}\$', 'date': t['created_at']});
  }
  activity.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

  return {
    'users':        (users as List).length,
    'requests':     (requests as List).length,
    'revenue':      totalRevenue,
    'pending_reports': (reports as List).length,
    'revenue_spots': revenueSpots,
    'activity':      activity.take(5).toList(),
  };
});


class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int _selectedIndex = 0;

  // Définition des pages avec leurs icônes respectives
  final List<Map<String, dynamic>> _adminPages = [
    {'title': 'Stats', 'icon': Icons.analytics_rounded},
    {'title': 'Utilisateurs', 'icon': Icons.people_rounded},
    {'title': 'Signalements', 'icon': Icons.flag_rounded},
    {'title': 'Waitlist', 'icon': Icons.hourglass_top_rounded},
    {'title': 'Catégories', 'icon': Icons.category_rounded},
    {'title': 'Litiges', 'icon': Icons.gavel_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDim, size: 20),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            // Un fond légèrement surélevé pour contraster avec le fond sombre de l'application
            color: const Color(0xFF1E2235),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.textMute.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedIndex,
              dropdownColor: const Color(0xFF1E2235),
              icon: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.amber, size: 22),
              ),
              // Option importante : aligne le menu verticalement sous la capsule
              alignment: Alignment.centerLeft,
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedIndex = newValue;
                  });
                }
              },
              // Personnalisation de l'élément sélectionné (dans la AppBar)
              selectedItemBuilder: (BuildContext context) {
                return _adminPages.map<Widget>((page) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(page['icon'], color: AppColors.amber, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        page['title'],
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
              // Personnalisation des éléments dans la liste déroulante ouverte
              items: List.generate(_adminPages.length, (index) {
                final page = _adminPages[index];
                final isSelected = index == _selectedIndex;

                return DropdownMenuItem<int>(
                  value: index,
                  child: Row(
                    children: [
                      Icon(
                          page['icon'],
                          color: isSelected ? AppColors.amber : AppColors.textMute,
                          size: 18
                      ),
                      const SizedBox(width: 12),
                      Text(
                        page['title'],
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.text : AppColors.textMute,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _StatsTab(statsAsync: statsAsync),
          const _UsersTab(),
          const _ReportsTab(),
          const _WaitlistTab(),
          const _CategoriesTab(),
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
      data: (stats) {
        final spots = (stats['revenue_spots'] as List).cast<FlSpot>();
        final activity = (stats['activity'] as List).cast<Map<String, dynamic>>();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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

              const SizedBox(height: 32),
              const Text(
                'Évolution des revenus (7j)',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                padding: const EdgeInsets.only(right: 16, top: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line2),
                ),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.green,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.green.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                'Activité récente',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              ...activity.map((item) {
                IconData icon;
                Color color;
                switch (item['type']) {
                  case 'user':
                    icon = Icons.person_add_rounded;
                    color = AppColors.cyan;
                    break;
                  case 'request':
                    icon = Icons.add_alert_rounded;
                    color = AppColors.amber;
                    break;
                  case 'transaction':
                    icon = Icons.payments_rounded;
                    color = AppColors.green;
                    break;
                  default:
                    icon = Icons.notifications_rounded;
                    color = AppColors.textMute;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line2),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['title'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      Text(
                        timeago.format(DateTime.parse(item['date']), locale: 'fr'),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMute,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
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
  ref.watch(adminRealtimeTriggerProvider);
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


// ── Providers pour l'onglet Litiges ───────────────────────

final showArchivedLitigesProvider = StateProvider<bool>((ref) => false);

final adminAllRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(adminRealtimeTriggerProvider);
  final showArchived = ref.watch(showArchivedLitigesProvider);

  final data = await _client
      .from('requests')
      .select()
      .eq('archived_by_admin', showArchived)
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
        requests[i] = {...requests[i], 'profiles': profile};
      } catch (_) {
        requests[i] = {...requests[i], 'profiles': null};
      }
    }
  }

  return requests;
});

Future<void> setRequestArchivedByAdmin(String requestId, bool archived) async {
  await _client
      .from('requests')
      .update({'archived_by_admin': archived})
      .eq('id', requestId);
}

// ── Onglet Litiges ────────────────────────────────────────
class _LitigesTab extends ConsumerStatefulWidget {
  const _LitigesTab();

  @override
  ConsumerState<_LitigesTab> createState() => _LitigesTabState();
}

class _LitigesTabState extends ConsumerState<_LitigesTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(adminAllRequestsProvider);
    final isArchivedView = ref.watch(showArchivedLitigesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: AppColors.text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par titre ou nom...',
                    hintStyle: const TextStyle(
                        color: AppColors.textMute, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textMute, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.surface2,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.line2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.line2),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 12),
              ArchiveToggle(provider: showArchivedLitigesProvider),
            ],
          ),
        ),
        Expanded(
          child: requestsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.amber),
            ),
            error: (e, _) => Center(
              child: Text('Erreur: $e',
                  style: const TextStyle(color: AppColors.red)),
            ),
            data: (requests) {
              final query = _searchQuery.toLowerCase();
              final filtered = query.isEmpty
                  ? requests
                  : requests.where((r) {
                final title =
                (r['title'] as String? ?? '').toLowerCase();
                final clientName = (r['profiles']?['full_name']
                as String? ?? '')
                    .toLowerCase();
                return title.contains(query) ||
                    clientName.contains(query);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          isArchivedView
                              ? Icons.archive_outlined
                              : Icons.search_off_rounded,
                          size: 40, color: AppColors.textMute),
                      const SizedBox(height: 12),
                      Text(
                        isArchivedView
                            ? 'Aucun litige archivé.'
                            : query.isEmpty
                            ? 'Aucun SOS pour l\'instant.'
                            : 'Aucun résultat pour "$_searchQuery".',
                        style: const TextStyle(
                            color: AppColors.textMute, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final req = filtered[i];
                  final title = req['title'] as String? ?? '';
                  final status = req['status'] as String? ?? '';
                  final category = req['category'] as String? ?? '';
                  final clientName =
                      req['profiles']?['full_name'] as String? ?? '—';
                  final createdAt = req['created_at'] != null
                      ? DateTime.parse(req['created_at'] as String)
                      : DateTime.now();

                  return GestureDetector(
                    onTap: () => _showDetail(context, ref, req),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.amberSoft,
                                        borderRadius:
                                        BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        category.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.amber,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: status == 'open'
                                            ? AppColors.greenSoft
                                            : status == 'in_progress'
                                            ? AppColors.cyanSoft
                                            : status == 'cancelled'
                                            ? AppColors.redSoft
                                            : AppColors.surface2,
                                        borderRadius:
                                        BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: status == 'open'
                                              ? AppColors.green
                                              : status == 'in_progress'
                                              ? AppColors.cyan
                                              : status == 'cancelled'
                                              ? AppColors.red
                                              : AppColors.textMute,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text,
                                    ),
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                  'Client: $clientName · ${timeago.format(createdAt, locale: 'fr')}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMute,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await setRequestArchivedByAdmin(
                                  req['id'] as String, !isArchivedView);
                              ref.invalidate(adminAllRequestsProvider);
                            },
                            icon: Icon(
                              isArchivedView
                                  ? Icons.unarchive_outlined
                                  : Icons.archive_outlined,
                              size: 18,
                              color: AppColors.textMute,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Détail complet d'un SOS (offres, facture, messages) ──
  Future<void> _showDetail(
      BuildContext context, WidgetRef ref, Map<String, dynamic> req) async {
    final requestId = req['id'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollCtrl) => _LitigeDetailSheet(
          requestId: requestId,
          request: req,
          scrollController: scrollCtrl,
        ),
      ),
    );
  }
}

// ── Bottom sheet de détail d'un litige ─────────────────────
class _LitigeDetailSheet extends ConsumerStatefulWidget {
  final String requestId;
  final Map<String, dynamic> request;
  final ScrollController scrollController;

  const _LitigeDetailSheet({
    required this.requestId,
    required this.request,
    required this.scrollController,
  });

  @override
  ConsumerState<_LitigeDetailSheet> createState() =>
      _LitigeDetailSheetState();
}

class _LitigeDetailSheetState extends ConsumerState<_LitigeDetailSheet> {
  List<Map<String, dynamic>>? _offers;
  List<Map<String, dynamic>>? _messages;
  Map<String, dynamic>? _invoice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      // Charger les offres avec profil prestataire
      final offersData = await _client
          .from('offers')
          .select()
          .eq('request_id', widget.requestId)
          .order('created_at', ascending: false);

      // Charger la facture (s'il y en a une)
      final invoiceData = await _client
          .from('invoices')
          .select()
          .eq('request_id', widget.requestId)
          .maybeSingle();

      // Charger les messages (via les offer_ids)
      final offers = List<Map<String, dynamic>>.from(offersData);
      for (int i = 0; i < offers.length; i++) {
        final providerId = offers[i]['provider_id'] as String?;
        if (providerId != null) {
          try {
            final profile = await _client
                .from('profiles')
                .select('full_name')
                .eq('id', providerId)
                .single();
            offers[i] = {...offers[i], 'profiles': profile};
          } catch (_) {
            offers[i] = {...offers[i], 'profiles': null};
          }
        }
      }
      final offerIds = offers.map((o) => o['id'] as String).toList();

      List<Map<String, dynamic>> allMessages = [];
      if (offerIds.isNotEmpty) {
        final msgsData = await _client
            .from('messages')
            .select()
            .inFilter('offer_id', offerIds)
            .order('created_at');
        final msgsList = List<Map<String, dynamic>>.from(msgsData);
        for (int i = 0; i < msgsList.length; i++) {
          final senderId = msgsList[i]['sender_id'] as String?;
          if (senderId != null) {
            try {
              final profile = await _client
                  .from('profiles')
                  .select('full_name')
                  .eq('id', senderId)
                  .single();
              msgsList[i] = {...msgsList[i], 'profiles': profile};
            } catch (_) {
              msgsList[i] = {...msgsList[i], 'profiles': null};
            }
          }
        }
        allMessages = msgsList;
      }

      if (mounted) {
        setState(() {
          _offers = offers;
          _invoice = invoiceData;
          _messages = allMessages;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final clientName = req['profiles']?['full_name'] as String? ?? '—';

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // ── Handle ──
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.line2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── SOS Info ──
        Text('Détail du SOS',
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            )),
        const SizedBox(height: 16),
        _InfoRow('Titre', req['title'] as String? ?? '—'),
        _InfoRow('Client', clientName),
        _InfoRow('Catégorie', req['category'] as String? ?? '—'),
        _InfoRow('Statut', req['status'] as String? ?? '—'),
        _InfoRow('Lieu', req['location'] as String? ?? '—'),
        _InfoRow('Urgence', req['urgency'] as String? ?? '—'),
        if (req['budget'] != null)
          _InfoRow('Budget', '${(req['budget'] as num).toStringAsFixed(0)}\$'),
        _InfoRow('Description', req['description'] as String? ?? '—'),

        if (_loading) ...[
          const SizedBox(height: 32),
          const Center(
              child: CircularProgressIndicator(color: AppColors.amber)),
        ] else ...[
          // ── Offres ──
          const SizedBox(height: 24),
          Text('Offres (${_offers?.length ?? 0})',
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              )),
          const SizedBox(height: 8),
          if (_offers == null || _offers!.isEmpty)
            const Text('Aucune offre.',
                style: TextStyle(color: AppColors.textMute, fontSize: 13))
          else
            ..._offers!.map((offer) {
              final providerName =
                  offer['profiles']?['full_name'] as String? ?? '—';
              final price = (offer['price'] as num?)?.toDouble() ?? 0;
              final status = offer['status'] as String? ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: status == 'accepted'
                      ? AppColors.greenSoft
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: status == 'accepted'
                        ? AppColors.green
                        : AppColors.line2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(providerName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            )),
                        Text('${price.toStringAsFixed(0)}\$',
                            style: const TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amber,
                            )),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Statut: $status',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMute)),
                    const SizedBox(height: 4),
                    Text(offer['message'] as String? ?? '',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textDim)),
                  ],
                ),
              );
            }),

          // ── Facture ──
          const SizedBox(height: 24),
          Text('Facture',
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              )),
          const SizedBox(height: 8),
          if (_invoice == null)
            const Text('Aucune facture.',
                style: TextStyle(color: AppColors.textMute, fontSize: 13))
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow('N°', _invoice!['invoice_number'] as String? ?? '—'),
                  _InfoRow('Montant',
                      '${(_invoice!['total_amount'] as num?)?.toStringAsFixed(2) ?? '—'}\$'),
                  _InfoRow('Statut', _invoice!['status'] as String? ?? '—'),
                ],
              ),
            ),

          // ── Messages ──
          const SizedBox(height: 24),
          Text('Messages (${_messages?.length ?? 0})',
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              )),
          const SizedBox(height: 8),
          if (_messages == null || _messages!.isEmpty)
            const Text('Aucun message.',
                style: TextStyle(color: AppColors.textMute, fontSize: 13))
          else
            ..._messages!.map((msg) {
              final senderName =
                  msg['profiles']?['full_name'] as String? ?? '—';
              final content = msg['content'] as String? ?? '';
              final sentAt = msg['created_at'] != null
                  ? DateTime.parse(msg['created_at'] as String)
                  : null;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(senderName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.amber,
                            )),
                        if (sentAt != null)
                          Text(
                            timeago.format(sentAt, locale: 'fr'),
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMute),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(content,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.text)),
                  ],
                ),
              );
            }),
          const SizedBox(height: 32),
        ],
      ],
    );
  }
}

// ── Widget utilitaire pour les lignes d'info ──────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMute,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.text)),
          ),
        ],
      ),
    );
  }
}