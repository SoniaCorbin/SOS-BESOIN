import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../requests/providers/request_provider.dart';
import '../../requests/models/request_model.dart';

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
                      final newRole = isProvider
                          ? UserRole.client
                          : UserRole.provider;
                      ref.read(authProvider.notifier).switchRole(newRole);
                    },
                    onSignOut: () =>
                        ref.read(authProvider.notifier).signOut(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ModeBadge(isProvider: isProvider),
                ),
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
        label: const Text(
          'Lancer un SOS',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ── AppBar ────────────────────────────────────────────────
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
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.bg,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'SOS·BESOIN',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSwitchRole,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isProvider ? AppColors.cyanSoft : AppColors.amberSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isProvider ? AppColors.cyan : AppColors.amber,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isProvider
                        ? Icons.handyman_rounded
                        : Icons.search_rounded,
                    size: 14,
                    color: isProvider ? AppColors.cyan : AppColors.amber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isProvider ? 'Mode Pro' : 'Mode Client',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isProvider ? AppColors.cyan : AppColors.amber,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 14,
                    color: isProvider ? AppColors.cyan : AppColors.amber,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.push(AppRoutes.profile),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface2,
                border: Border.all(color: AppColors.line2),
              ),
              child: Center(
                child: Text(
                  user?.initials ?? '?',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onSignOut,
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textMute,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge mode actif ──────────────────────────────────────
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
                : AppColors.amber.withValues(alpha: 0.4),
          ),
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
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isProvider
                  ? 'Mode Prestataire — Vous recevez des missions'
                  : 'Mode Client — Trouvez un pro rapidement',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isProvider ? AppColors.cyan2 : AppColors.amber2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard Client ──────────────────────────────────────
class _ClientDashboard extends ConsumerWidget {
  final dynamic user;

  const _ClientDashboard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Bonjour, ${currentUser?.fullName.split(' ').first ?? 'là'} 👋',
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'De quoi avez-vous besoin aujourd\'hui ?',
            style: TextStyle(fontSize: 15, color: AppColors.textDim),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              _StatChip(
                icon: Icons.history_rounded,
                label: 'Demandes',
                value: '0',
                color: AppColors.amber,
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.check_circle_outline_rounded,
                label: 'Complétées',
                value: '0',
                color: AppColors.green,
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.pending_outlined,
                label: 'En cours',
                value: '0',
                color: AppColors.cyan,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Catégories populaires',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: const [
              _CategoryChip(icon: Icons.computer_rounded,       label: 'Tech'),
              _CategoryChip(icon: Icons.music_note_rounded,     label: 'Musique'),
              _CategoryChip(icon: Icons.build_rounded,          label: 'Réparation'),
              _CategoryChip(icon: Icons.local_shipping_rounded, label: 'Transport'),
              _CategoryChip(icon: Icons.school_rounded,         label: 'Cours'),
              _CategoryChip(icon: Icons.more_horiz_rounded,     label: 'Autre'),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Vos demandes récentes',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          const _MyRequestsList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ── Dashboard Prestataire ─────────────────────────────────
class _ProviderDashboard extends StatelessWidget {
  final dynamic user;

  const _ProviderDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Bonjour, ${user?.fullName.split(' ').first ?? 'Pro'} 👋',
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Voici les missions disponibles près de vous.',
            style: TextStyle(fontSize: 15, color: AppColors.textDim),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              _StatChip(
                icon: Icons.attach_money_rounded,
                label: 'Ce mois',
                value: '0\$',
                color: AppColors.green,
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.star_rounded,
                label: 'Note',
                value: user?.rating.toStringAsFixed(1) ?? '—',
                color: AppColors.amber,
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.task_alt_rounded,
                label: 'Missions',
                value: '${user?.totalMissions ?? 0}',
                color: AppColors.cyan,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Missions disponibles',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
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

    return requestsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: AppColors.cyan, strokeWidth: 2,
          ),
        ),
      ),
      error: (e, _) => Text('Erreur: $e',
          style: const TextStyle(color: AppColors.red)),
      data: (requests) => requests.isEmpty
          ? Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line2),
        ),
        child: const Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 40, color: AppColors.textMute),
            SizedBox(height: 12),
            Text(
              'Aucune mission pour l\'instant',
              style: TextStyle(
                  color: AppColors.textMute, fontSize: 14),
            ),
          ],
        ),
      )
          : Column(
        children: requests.map((r) => GestureDetector(
          onTap: () => context.push('/request/${r.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: r.status == 'in_progress'
                    ? AppColors.cyan
                    : AppColors.line2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMute,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: r.status == 'in_progress'
                        ? AppColors.cyanSoft
                        : AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    r.status == 'in_progress'
                        ? 'En cours'
                        : 'Ouvert',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: r.status == 'in_progress'
                          ? AppColors.cyan
                          : AppColors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}

// ── Liste demandes client ─────────────────────────────────
class _MyRequestsList extends ConsumerWidget {
  const _MyRequestsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: AppColors.amber, strokeWidth: 2,
          ),
        ),
      ),
      error: (e, _) => Text('Erreur: $e',
          style: const TextStyle(color: AppColors.red)),
      data: (requests) => requests.isEmpty
          ? Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line2),
        ),
        child: const Column(
          children: [
            Icon(Icons.inbox_outlined,
                size: 40, color: AppColors.textMute),
            SizedBox(height: 12),
            Text(
              'Aucune demande pour l\'instant',
              style: TextStyle(
                  color: AppColors.textMute, fontSize: 14),
            ),
          ],
        ),
      )
          : Column(
        children: requests.map((r) => GestureDetector(
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.amberSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    r.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber,
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMute,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: r.status == 'open'
                        ? AppColors.greenSoft
                        : AppColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    r.status == 'open' ? 'Ouvert' : r.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: r.status == 'open'
                          ? AppColors.green
                          : AppColors.textMute,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}

// ── Liste missions ouvertes (prestataire) ─────────────────
class _OpenRequestsList extends ConsumerWidget {
  const _OpenRequestsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(openRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: AppColors.cyan, strokeWidth: 2,
          ),
        ),
      ),
      error: (e, _) => Text('Erreur: $e',
          style: const TextStyle(color: AppColors.red)),
      data: (requests) => requests.isEmpty
          ? Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line2),
        ),
        child: const Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 40, color: AppColors.textMute),
            SizedBox(height: 12),
            Text(
              'Aucune mission disponible pour l\'instant',
              style: TextStyle(
                  color: AppColors.textMute, fontSize: 14),
            ),
          ],
        ),
      )
          : Column(
        children: requests.map((r) => GestureDetector(
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMute,
                        ),
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
                      color: AppColors.amber,
                    ),
                  ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
                  fontSize: 11, color: AppColors.textMute),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category chip ─────────────────────────────────────────
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
        border: Border.all(color: AppColors.line2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: AppColors.amber),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Navigation ─────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final bool isProvider;

  const _BottomNav({required this.isProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: isProvider ? AppColors.cyan : AppColors.amber,
        unselectedItemColor: AppColors.textMute,
        selectedLabelStyle: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        currentIndex: 0,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt_outlined),
            activeIcon: const Icon(Icons.list_alt_rounded),
            label: isProvider ? 'Missions' : 'Demandes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Factures',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}