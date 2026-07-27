import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../requests/providers/request_provider.dart';
import '../../requests/models/request_model.dart';
import '../../requests/screens/request_detail_screen.dart' show requestOffersProvider;
import '../../../../core/services/geolocation_service.dart';
import '../../invoices/providers/invoice_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState  = ref.watch(authProvider);
    final user       = authState.user;
    final isProvider = authState.activeRole == UserRole.provider;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -150, left: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.amber.withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            top: 100, right: -150,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.cyan.withValues(alpha: 0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HomeAppBar(
                    user: user,
                    isProvider: isProvider,
                    onSwitchRole: () {
                      final newRole = isProvider ? UserRole.client : UserRole.provider;
                      ref.read(authProvider.notifier).switchRole(newRole);
                    },
                    onSignOut: () => ref.read(authProvider.notifier).signOut(),
                  ),
                ),
                SliverToBoxAdapter(child: _ModeBadge(isProvider: isProvider)),
                SliverToBoxAdapter(
                  child: isProvider
                      ? _ProviderDashboard(user: user)
                      : _ClientDashboard(user: user),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(isProvider: isProvider),
      floatingActionButton: !isProvider
          ? FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.requestCreate),
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.bg,
        icon: const Icon(Icons.warning_amber_rounded),
        label: Text('home_sos_btn'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _HomeAppBar extends ConsumerWidget {
  final dynamic user;
  final bool isProvider;
  final VoidCallback onSwitchRole;
  final VoidCallback onSignOut;

  const _HomeAppBar({
    required this.user,
    required this.isProvider,
    required this.onSwitchRole,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: AppColors.gradientAmber,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.bg, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'app_name'.tr(),
            style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSwitchRole,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isProvider ? AppColors.cyanSoft : AppColors.amberSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isProvider ? AppColors.cyan : AppColors.amber),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      isProvider
                          ? Icons.handyman_rounded
                          : Icons.search_rounded,
                      size: 13,
                      color: isProvider ? AppColors.cyan : AppColors.amber),
                  const SizedBox(width: 4),
                  Text(
                      isProvider ? 'Pro' : 'Client',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isProvider ? AppColors.cyan : AppColors.amber)),
                  const SizedBox(width: 3),
                  Icon(Icons.swap_horiz_rounded,
                      size: 13,
                      color: isProvider ? AppColors.cyan : AppColors.amber),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push(AppRoutes.profile),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface2,
                  border: Border.all(color: AppColors.line2)),
              child: Center(
                  child: Text(user?.initials ?? '?',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text))),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onSignOut,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.textMute, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final bool isProvider;
  const _ModeBadge({required this.isProvider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isProvider ? AppColors.cyanSoft : AppColors.amberSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isProvider
                  ? AppColors.cyan.withValues(alpha: 0.4)
                  : AppColors.amber.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isProvider ? AppColors.cyan : AppColors.amber,
                boxShadow: [
                  BoxShadow(
                      color: isProvider
                          ? AppColors.cyan.withValues(alpha: 0.6)
                          : AppColors.amber.withValues(alpha: 0.6),
                      blurRadius: 6)
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isProvider
                    ? 'home_mode_provider'.tr()
                    : 'home_mode_client'.tr(),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isProvider ? AppColors.cyan2 : AppColors.amber2),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientDashboard extends ConsumerWidget {
  final dynamic user;
  const _ClientDashboard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final statsAsync = ref.watch(clientRequestStatsProvider);
    final pendingOffers = ref
        .watch(pendingOffersCountProvider)
        .maybeWhen(data: (n) => n, orElse: () => 0);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'home_greeting'.tr(namedArgs: {
              'name': currentUser?.fullName.split(' ').first ?? 'là'
            }),
            style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text('home_client_subtitle'.tr(),
              style: const TextStyle(fontSize: 15, color: AppColors.textDim)),
          const SizedBox(height: 28),
          Row(
            children: [
              _StatChip(
                icon: Icons.history_rounded,
                label: 'stat_requests'.tr(),
                value: statsAsync.maybeWhen(
                    data: (s) => '${s.total}', orElse: () => '0'),
                color: AppColors.amber,
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.check_circle_outline_rounded,
                label: 'stat_completed'.tr(),
                value: statsAsync.maybeWhen(
                    data: (s) => '${s.completed}', orElse: () => '0'),
                color: AppColors.green,
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.pending_outlined,
                label: 'stat_in_progress'.tr(),
                value: statsAsync.maybeWhen(
                    data: (s) => '${s.inProgress}', orElse: () => '0'),
                color: AppColors.cyan,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PendingOffersBanner(count: pendingOffers),
          const SizedBox(height: 32),
          Text('home_popular_categories'.tr(),
              style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _CategoryChip(icon: Icons.computer_rounded, label: 'cat_tech'.tr()),
              _CategoryChip(icon: Icons.music_note_rounded, label: 'cat_music'.tr()),
              _CategoryChip(icon: Icons.build_rounded, label: 'cat_repair'.tr()),
              _CategoryChip(icon: Icons.local_shipping_rounded, label: 'cat_transport'.tr()),
              _CategoryChip(icon: Icons.school_rounded, label: 'cat_courses'.tr()),
              _CategoryChip(icon: Icons.more_horiz_rounded, label: 'cat_other'.tr()),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('home_recent_requests'.tr(),
                  style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              _ArchiveToggle(provider: showArchivedRequestsProvider),
            ],
          ),
          const SizedBox(height: 16),
          const _MyRequestsList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// Bandeau "Offres en attente" — distinct visuellement des 3 carrés de
// stats historiques : il s'illumine (fond/bordure amber + icône pleine)
// quand des offres attendent une réponse, et reste discret sinon.
class _PendingOffersBanner extends StatelessWidget {
  final int count;
  const _PendingOffersBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final hasPending = count > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: hasPending ? AppColors.amberSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasPending ? AppColors.amber : AppColors.line2,
          width: hasPending ? 1.5 : 1,
        ),
        boxShadow: hasPending
            ? [
          BoxShadow(
            color: AppColors.amber.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ]
            : null,
      ),
      child: Row(
        children: [
          Icon(
            hasPending
                ? Icons.local_offer_rounded
                : Icons.local_offer_outlined,
            size: 20,
            color: hasPending ? AppColors.amber : AppColors.textMute,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasPending
                  ? 'stat_pending_offers'.tr(namedArgs: {'count': '$count'})
                  : 'stat_no_pending_offers'.tr(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: hasPending ? FontWeight.w700 : FontWeight.w500,
                color: hasPending ? AppColors.amber : AppColors.textMute,
              ),
            ),
          ),
          if (hasPending)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.amber,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.bg,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProviderDashboard extends ConsumerWidget {
  final dynamic user;
  const _ProviderDashboard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyRevenue = ref
        .watch(providerMonthlyRevenueProvider)
        .maybeWhen(data: (v) => v, orElse: () => 0.0);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'home_greeting'.tr(namedArgs: {
              'name': user?.fullName.split(' ').first ?? 'Pro'
            }),
            style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text('home_provider_subtitle'.tr(),
              style: const TextStyle(fontSize: 15, color: AppColors.textDim)),
          const SizedBox(height: 28),
          Row(
            children: [
              _StatChip(icon: Icons.attach_money_rounded, label: 'stat_this_month'.tr(), value: '${monthlyRevenue.toStringAsFixed(0)}\$', color: AppColors.green),
              const SizedBox(width: 12),
              _StatChip(icon: Icons.star_rounded, label: 'stat_rating'.tr(), value: user?.rating.toStringAsFixed(1) ?? '—', color: AppColors.amber),
              const SizedBox(width: 12),
              _StatChip(icon: Icons.task_alt_rounded, label: 'stat_missions'.tr(), value: '${user?.totalMissions ?? 0}', color: AppColors.cyan),
            ],
          ),
          const SizedBox(height: 32),
          Text('home_new_missions'.tr(),
              style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          const SizedBox(height: 16),
          const _OpenRequestsList(),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('home_my_missions'.tr(),
                  style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              _ArchiveToggle(provider: showArchivedMissionsProvider),
            ],
          ),
          const SizedBox(height: 16),
          const _ProviderMissionsList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _ProviderMissionsList extends ConsumerWidget {
  const _ProviderMissionsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myProviderRequestsProvider);
    final isArchivedView = ref.watch(showArchivedMissionsProvider);

    return requestsAsync.when(
      loading: () => const Center(
          child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                  color: AppColors.cyan, strokeWidth: 2))),
      error: (e, _) => Text('${'chat_error'.tr()}$e',
          style: const TextStyle(color: AppColors.red)),
      data: (requests) => requests.isEmpty
          ? Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line2)),
        child: Column(
          children: [
            Icon(
                isArchivedView
                    ? Icons.archive_outlined
                    : Icons.search_off_rounded,
                size: 40, color: AppColors.textMute),
            const SizedBox(height: 12),
            Text(
                isArchivedView
                    ? 'mission_no_archived'.tr()
                    : 'home_no_missions'.tr(),
                style: const TextStyle(
                    color: AppColors.textMute, fontSize: 14)),
          ],
        ),
      )
          : Column(
        children: requests
            .map((r) => _ProviderMissionCard(request: r))
            .toList(),
      ),
    );
  }
}

// Carte d'une demande du client, avec badge "offres reçues" mis à jour
// en temps réel (via requestOffersProvider) — visible sans avoir à
// cliquer sur la demande.
class _MyRequestCard extends ConsumerWidget {
  final RequestModel request;
  const _MyRequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = request;
    final offersCount = ref
        .watch(requestOffersProvider(r.id))
        .maybeWhen(data: (offers) => offers.length, orElse: () => 0);
    final hasNewOffers = r.status == 'open' && offersCount > 0;
    final isArchivedView = ref.watch(showArchivedRequestsProvider);

    return GestureDetector(
      onTap: () => context.push('/request/${r.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: hasNewOffers ? AppColors.amber : AppColors.line2,
                width: hasNewOffers ? 1.5 : 1)),
        child: Row(
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(r.category.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(r.location,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMute)),
                ],
              ),
            ),
            if (hasNewOffers) ...[
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_offer_rounded,
                        size: 11, color: AppColors.bg),
                    const SizedBox(width: 4),
                    Text(
                      '$offersCount',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.bg),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: r.status == 'open'
                    ? AppColors.greenSoft
                    : AppColors.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                r.status == 'open'
                    ? 'status_open'.tr()
                    : r.status == 'cancelled'
                    ? 'request_status_cancelled'.tr()
                    : r.status,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: r.status == 'open'
                        ? AppColors.green
                        : AppColors.textMute),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _toggleArchive(context, ref, r.id, isArchivedView),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: Icon(
                isArchivedView
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
                size: 16,
                color: AppColors.textMute,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleArchive(
      BuildContext context, WidgetRef ref, String requestId, bool currentlyArchived) async {
    await setRequestArchivedByClient(requestId, !currentlyArchived);
    ref.invalidate(myRequestsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentlyArchived
              ? 'request_unarchived_snack'.tr()
              : 'request_archived_snack'.tr()),
          backgroundColor: AppColors.surface2,
        ),
      );
    }
  }
}

class _ProviderMissionCard extends ConsumerWidget {
  final RequestModel request;
  const _ProviderMissionCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = request;
    final isArchivedView = ref.watch(showArchivedMissionsProvider);

    return GestureDetector(
      onTap: () => context.push('/request/${r.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cyanSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                r.category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyan,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.location,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMute),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: r.status == 'open'
                    ? AppColors.greenSoft
                    : r.status == 'in_progress'
                    ? AppColors.cyanSoft
                    : AppColors.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                r.status == 'open'
                    ? 'status_open'.tr()
                    : r.status == 'in_progress'
                    ? 'status_in_progress'.tr()
                    : r.status == 'cancelled'
                    ? 'request_status_cancelled'.tr()
                    : r.status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: r.status == 'open'
                      ? AppColors.green
                      : r.status == 'in_progress'
                      ? AppColors.cyan
                      : AppColors.textMute,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _toggleArchive(context, ref, r.id, isArchivedView),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: Icon(
                isArchivedView
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
                size: 16,
                color: AppColors.textMute,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleArchive(BuildContext context, WidgetRef ref,
      String requestId, bool currentlyArchived) async {
    await setRequestArchivedByProvider(requestId, !currentlyArchived);
    ref.invalidate(myProviderRequestsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentlyArchived
              ? 'mission_unarchived_snack'.tr()
              : 'mission_archived_snack'.tr()),
          backgroundColor: AppColors.surface2,
        ),
      );
    }
  }
}

class _MyRequestsList extends ConsumerWidget {
  const _MyRequestsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myRequestsProvider);
    final isArchivedView = ref.watch(showArchivedRequestsProvider);

    return requestsAsync.when(
        loading: () => const Center(
            child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                    color: AppColors.amber, strokeWidth: 2))),
        error: (e, _) => Text('${'chat_error'.tr()}$e',
            style: const TextStyle(color: AppColors.red)),
        data: (requests) => requests.isEmpty
            ? Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line2)),
          child: Column(
            children: [
              Icon(
                  isArchivedView
                      ? Icons.archive_outlined
                      : Icons.inbox_outlined,
                  size: 40, color: AppColors.textMute),
              const SizedBox(height: 12),
              Text(
                  isArchivedView
                      ? 'request_no_archived'.tr()
                      : 'home_no_requests'.tr(),
                  style: const TextStyle(
                      color: AppColors.textMute, fontSize: 14)),
            ],
          ),
        )
            : Column(
          children: requests.map((r) => _MyRequestCard(request: r)).toList(),
      ),
    );
  }
}

class _OpenRequestsList extends ConsumerStatefulWidget {
  const _OpenRequestsList();

  @override
  ConsumerState<_OpenRequestsList> createState() => _OpenRequestsListState();
}

class _OpenRequestsListState extends ConsumerState<_OpenRequestsList> {
  double? _myLat;
  double? _myLng;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    final pos = await GeolocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _myLat = pos.latitude;
        _myLng = pos.longitude;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(openRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(
          child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                  color: AppColors.cyan, strokeWidth: 2))),
      error: (e, _) => Text('${'chat_error'.tr()}$e',
          style: const TextStyle(color: AppColors.red)),
      data: (requests) {
        final user = ref.read(authProvider).user;
        final maxKm = user?.maxDistanceKm ?? 500;
        final filtered = requests.where((r) {
          if (_myLat == null || r.latitude == null || r.longitude == null)
            return true;
          final dist = GeolocationService.calculateDistance(
              _myLat!, _myLng!, r.latitude!, r.longitude!);
          return dist <= maxKm;
        }).toList();

        return filtered.isEmpty
            ? Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line2)),
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 40, color: AppColors.textMute),
              const SizedBox(height: 12),
              Text('home_no_open_missions'.tr(),
                  style: const TextStyle(
                      color: AppColors.textMute, fontSize: 14)),
            ],
          ),
        )
            : Column(
          children: filtered.map((r) => GestureDetector(
            onTap: () => context.push('/request/${r.id}'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line2)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.cyanSoft,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(r.category.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cyan)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(r.location,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMute)),
                            if (_myLat != null &&
                                r.latitude != null &&
                                r.longitude != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '· ${GeolocationService.formatDistance(GeolocationService.calculateDistance(_myLat!, _myLng!, r.latitude!, r.longitude!))}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.cyan,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (r.budget != null)
                    Text(
                      '${r.budget!.toStringAsFixed(0)}\$',
                      style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber),
                    ),
                ],
              ),
            ),
          )).toList(),
        );
      },
    );
  }
}

// Toggle réutilisable "Actifs / Archivés" — prend le StateProvider<bool>
// à contrôler en paramètre pour être réutilisé sur les listes SOS,
// missions et conversations.
class _ArchiveToggle extends ConsumerWidget {
  final StateProvider<bool> provider;
  const _ArchiveToggle({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showArchived = ref.watch(provider);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ArchiveToggleTab(
            label: 'toggle_active'.tr(),
            selected: !showArchived,
            onTap: () => ref.read(provider.notifier).state = false,
          ),
          _ArchiveToggleTab(
            label: 'toggle_archived'.tr(),
            selected: showArchived,
            onTap: () => ref.read(provider.notifier).state = true,
          ),
        ],
      ),
    );
  }
}

class _ArchiveToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ArchiveToggleTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.bg : AppColors.textMute,
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.icon,
        required this.label,
        required this.value,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMute)),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CategoryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line2)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: AppColors.amber),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDim)),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final bool isProvider;
  const _BottomNav({required this.isProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line))),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: isProvider ? AppColors.cyan : AppColors.amber,
        unselectedItemColor: AppColors.textMute,
        selectedLabelStyle:
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0: context.go(AppRoutes.home); break;
            case 1: context.push(AppRoutes.history); break;
            case 2: context.push('/conversations'); break;
            case 3: context.push(AppRoutes.invoices); break;
            case 4: context.push(AppRoutes.profile); break;
          }
        },
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded),
              label: 'nav_home'.tr()),
          BottomNavigationBarItem(
              icon: const Icon(Icons.list_alt_outlined),
              activeIcon: const Icon(Icons.list_alt_rounded),
              label: isProvider ? 'nav_missions'.tr() : 'nav_requests'.tr()),
          BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: const Icon(Icons.chat_bubble_rounded),
              label: 'nav_messages'.tr()),
          BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long_rounded),
              label: 'nav_invoices'.tr()),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: 'nav_profile'.tr()),
        ],
      ),
    );
  }
}