import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  UserRole? _selected;
  bool _loading = false;

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    await ref.read(authProvider.notifier).switchRole(_selected!);
    if (!mounted) return;
    setState(() => _loading = false);
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ── Glows ─────────────────────────────────────
          Positioned(
            top: -150, left: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.amber.withValues(alpha: 0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -100, right: -100,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.cyan.withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // ── Contenu ───────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  // Titre
                  const Text(
                    'Comment voulez-vous\ncommencer ?',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                      letterSpacing: -0.8,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Vous pourrez changer de mode à tout moment\ndans votre profil.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textDim,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Carte Client
                  _RoleCard(
                    role: UserRole.client,
                    selected: _selected == UserRole.client,
                    icon: Icons.search_rounded,
                    title: 'Je suis un client',
                    subtitle: 'Je cherche un professionnel\npour un besoin urgent.',
                    color: AppColors.amber,
                    softColor: AppColors.amberSoft,
                    bullets: const [
                      'Publiez une demande en 90 secondes',
                      'Recevez des offres de pros vérifiés',
                      'Payez seulement après validation',
                    ],
                    onTap: () => setState(() => _selected = UserRole.client),
                  ),
                  const SizedBox(height: 16),
                  // Carte Prestataire
                  _RoleCard(
                    role: UserRole.provider,
                    selected: _selected == UserRole.provider,
                    icon: Icons.handyman_rounded,
                    title: 'Je suis un prestataire',
                    subtitle: 'Je propose mes services\npour des missions urgentes.',
                    color: AppColors.cyan,
                    softColor: AppColors.cyanSoft,
                    bullets: const [
                      'Recevez des missions près de chez vous',
                      'Fixez vos propres tarifs',
                      'Paiement garanti sous 24h',
                    ],
                    onTap: () => setState(() => _selected = UserRole.provider),
                  ),
                  const Spacer(),
                  // Bouton confirmer
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_selected == null || _loading)
                          ? null
                          : _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selected == UserRole.provider
                            ? AppColors.cyan
                            : AppColors.amber,
                        disabledBackgroundColor:
                        AppColors.surface2,
                      ),
                      child: _loading
                          ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.bg,
                        ),
                      )
                          : Text(
                        _selected == null
                            ? 'Choisissez un mode'
                            : 'Continuer',
                        style: TextStyle(
                          color: _selected == null
                              ? AppColors.textMute
                              : AppColors.bg,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget carte de rôle ──────────────────────────────────
class _RoleCard extends StatelessWidget {
  final UserRole role;
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color softColor;
  final List<String> bullets;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.softColor,
    required this.bullets,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? softColor : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppColors.line2,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: selected ? color : AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? AppColors.bg : AppColors.textDim,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: selected ? color : AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDim,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? color : AppColors.line2,
                      width: 2,
                    ),
                    color: selected ? color : Colors.transparent,
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 14, color: AppColors.bg)
                      : null,
                ),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 16),
              const Divider(color: AppColors.line),
              const SizedBox(height: 12),
              ...bullets.map(
                    (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 16, color: color),
                      const SizedBox(width: 10),
                      Text(
                        b,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}