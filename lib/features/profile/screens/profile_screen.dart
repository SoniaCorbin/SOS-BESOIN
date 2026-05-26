import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../../../core/router/app_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _editing    = false;
  bool _loading    = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameCtrl.text  = user?.fullName ?? '';
    _phoneCtrl.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      print('SAVING PROFILE: userId=$userId, name=${_nameCtrl.text.trim()}');

      await Supabase.instance.client.from('profiles').update({
        'full_name': _nameCtrl.text.trim(),
        'phone':     _phoneCtrl.text.trim(),
      }).eq('id', userId!);

      print('PROFILE SAVED!');
      // Refresh auth state
      await ref.read(authProvider.notifier).init();
      print('AUTH REFRESHED!');

      if (mounted) {
        setState(() { _editing = false; _loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil mis à jour !'),
            backgroundColor: AppColors.green,
          ),
        );
        // Forcer le refresh en retournant au home
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState  = ref.watch(authProvider);
    final user       = authState.user;
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
          'Mon profil',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_editing) {
                _save();
              } else {
                setState(() => _editing = true);
              }
            },
            child: Text(
              _editing ? 'Sauvegarder' : 'Modifier',
              style: TextStyle(
                color: isProvider ? AppColors.cyan : AppColors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar ──────────────────────────────────
            const SizedBox(height: 16),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isProvider
                          ? const LinearGradient(
                          colors: [AppColors.cyan, AppColors.cyan2])
                          : AppColors.gradientAmber,
                      boxShadow: [
                        BoxShadow(
                          color: isProvider
                              ? AppColors.cyan.withValues(alpha: 0.4)
                              : AppColors.amber.withValues(alpha: 0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user?.initials ?? '?',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.bg,
                        ),
                      ),
                    ),
                  ),
                  if (_editing)
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface2,
                          border: Border.all(color: AppColors.line2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: AppColors.textDim,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Nom
            Text(
              user?.fullName ?? '',
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMute,
              ),
            ),
            const SizedBox(height: 8),
            // Badge rôle
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isProvider
                    ? AppColors.cyanSoft
                    : AppColors.amberSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isProvider
                      ? AppColors.cyan
                      : AppColors.amber,
                ),
              ),
              child: Text(
                isProvider ? 'Mode Prestataire' : 'Mode Client',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isProvider
                      ? AppColors.cyan
                      : AppColors.amber,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // ── Stats ────────────────────────────────────
            Row(
              children: [
                _ProfileStat(
                  label: 'Note',
                  value: user?.rating.toStringAsFixed(1) ?? '—',
                  icon: Icons.star_rounded,
                  color: AppColors.amber,
                ),
                _ProfileStat(
                  label: 'Missions',
                  value: '${user?.totalMissions ?? 0}',
                  icon: Icons.task_alt_rounded,
                  color: AppColors.cyan,
                ),
                _ProfileStat(
                  label: 'KYC',
                  value: user?.isKycVerified == true
                      ? 'Vérifié'
                      : 'En attente',
                  icon: Icons.verified_rounded,
                  color: user?.isKycVerified == true
                      ? AppColors.green
                      : AppColors.textMute,
                ),
              ],
            ),
            const SizedBox(height: 32),
            // ── Infos ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations personnelles',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nom
                  _editing
                      ? TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(
                        color: AppColors.text),
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.textMute),
                    ),
                  )
                      : _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Nom complet',
                    value: user?.fullName ?? '—',
                  ),
                  const SizedBox(height: 12),
                  // Email (non modifiable)
                  _InfoRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Courriel',
                    value: user?.email ?? '—',
                  ),
                  const SizedBox(height: 12),
                  // Téléphone
                  _editing
                      ? TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                        color: AppColors.text),
                    decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: AppColors.textMute),
                    ),
                  )
                      : _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Téléphone',
                    value: user?.phone?.isNotEmpty == true
                        ? user!.phone!
                        : 'Non renseigné',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ── Switch de rôle ───────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mode actif',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleButton(
                          label: 'Client',
                          icon: Icons.search_rounded,
                          isActive: !isProvider,
                          color: AppColors.amber,
                          onTap: () => ref
                              .read(authProvider.notifier)
                              .switchRole(UserRole.client),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RoleButton(
                          label: 'Prestataire',
                          icon: Icons.handyman_rounded,
                          isActive: isProvider,
                          color: AppColors.cyan,
                          onTap: () => ref
                              .read(authProvider.notifier)
                              .switchRole(UserRole.provider),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── Pages légales ────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line2),
              ),
              child: Column(
                children: [
                  _LegalButton(
                    icon: Icons.description_outlined,
                    label: 'Conditions d\'utilisation',
                    onTap: () => context.push('/terms'),
                  ),
                  const Divider(color: AppColors.line, height: 1),
                  _LegalButton(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Politique de confidentialité',
                    onTap: () => context.push('/privacy'),
                  ),
                  const Divider(color: AppColors.line, height: 1),
                  _LegalButton(
                    icon: Icons.replay_outlined,
                    label: 'Politique de remboursement',
                    onTap: () => context.push('/refund')
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ── Déconnexion ──────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () =>
                    ref.read(authProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Se déconnecter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Stat profil ───────────────────────────────────────────
class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 16,
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

// ── Info row ──────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMute),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMute,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Bouton rôle ───────────────────────────────────────────
class _RoleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : AppColors.line2,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20,
                color: isActive ? color : AppColors.textMute),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? color : AppColors.textMute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _LegalButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LegalButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textDim),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textDim,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textMute,
            ),
          ],
        ),
      ),
    );
  }
}