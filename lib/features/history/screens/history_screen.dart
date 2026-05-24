import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/history_provider.dart';
import '../models/transaction_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState  = ref.watch(authProvider);
    final isProvider = authState.activeRole == UserRole.provider;

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
          'Historique',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: isProvider
          ? _ProviderHistory(ref: ref)
          : _ClientHistory(ref: ref),
    );
  }
}

// ── Historique client ─────────────────────────────────────
class _ClientHistory extends StatelessWidget {
  final WidgetRef ref;

  const _ClientHistory({required this.ref});

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(clientHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      ),
      error: (e, _) => Center(
        child: Text('Erreur: $e',
            style: const TextStyle(color: AppColors.red)),
      ),
      data: (transactions) => transactions.isEmpty
          ? _EmptyHistory(
        icon: Icons.history_rounded,
        message: 'Aucune transaction pour l\'instant',
        subtitle: 'Vos achats apparaîtront ici.',
      )
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: transactions.length,
        itemBuilder: (context, i) => _TransactionCard(
          transaction: transactions[i],
          isClient: true,
        ),
      ),
    );
  }
}

// ── Historique prestataire ────────────────────────────────
class _ProviderHistory extends StatelessWidget {
  final WidgetRef ref;

  const _ProviderHistory({required this.ref});

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(providerHistoryProvider);
    final statsAsync   = ref.watch(providerStatsProvider);

    return historyAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      ),
      error: (e, _) => Center(
        child: Text('Erreur: $e',
            style: const TextStyle(color: AppColors.red)),
      ),
      data: (transactions) => CustomScrollView(
        slivers: [
          // Stats
          SliverToBoxAdapter(
            child: statsAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (stats) => Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _StatCard(
                      label: 'Total gagné',
                      value: '${(stats['total_earned'] as double).toStringAsFixed(0)}\$',
                      color: AppColors.green,
                      icon: Icons.attach_money_rounded,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Ce mois',
                      value: '${(stats['this_month'] as double).toStringAsFixed(0)}\$',
                      color: AppColors.cyan,
                      icon: Icons.calendar_month_rounded,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Missions',
                      value: '${stats['total_missions']}',
                      color: AppColors.amber,
                      icon: Icons.task_alt_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Liste
          transactions.isEmpty
              ? SliverToBoxAdapter(
            child: _EmptyHistory(
              icon: Icons.work_history_rounded,
              message: 'Aucune mission complétée',
              subtitle: 'Vos revenus apparaîtront ici.',
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: _TransactionCard(
                  transaction: transactions[i],
                  isClient: false,
                ),
              ),
              childCount: transactions.length,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte transaction ─────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final bool isClient;

  const _TransactionCard({
    required this.transaction,
    required this.isClient,
  });

  @override
  Widget build(BuildContext context) {
    final amount = isClient
        ? transaction.amount
        : transaction.providerAmount;

    final formatter = DateFormat('d MMM yyyy', 'fr_CA');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line2),
      ),
      child: Row(
        children: [
          // Emoji catégorie
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                transaction.categoryEmoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.requestTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isClient
                      ? transaction.providerName
                      : transaction.clientName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMute,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(transaction.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMute,
                  ),
                ),
              ],
            ),
          ),
          // Montant + statut
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isClient
                    ? '-${amount.toStringAsFixed(0)}\$'
                    : '+${amount.toStringAsFixed(0)}\$',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isClient ? AppColors.red : AppColors.green,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(transaction.status)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  transaction.statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(transaction.status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed: return AppColors.green;
      case TransactionStatus.cancelled: return AppColors.red;
      case TransactionStatus.refunded:  return AppColors.violet;
      default:                          return AppColors.amber;
    }
  }
}

// ── Stat card ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
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

// ── Empty state ───────────────────────────────────────────
class _EmptyHistory extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyHistory({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMute),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDim,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMute,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}