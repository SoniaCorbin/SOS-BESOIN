import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      tag: '·URGENCE·',
      title: 'Un besoin\nurgent ?',
      accent: 'Posté en 90 secondes.',
      subtitle: 'Décrivez votre besoin. Des prestataires disponibles près de chez vous répondent en direct.',
      emoji: '🚨',
      color: AppColors.amber,
    ),
    _OnboardingData(
      tag: '·CONFIANCE·',
      title: 'Prestataires\nvérifiés.',
      accent: 'Identité confirmée.',
      subtitle: 'Chaque prestataire passe une vérification d\'identité (KYC) avant de pouvoir soumettre des offres.',
      emoji: '🛡️',
      color: AppColors.cyan,
    ),
    _OnboardingData(
      tag: '·SÉCURITÉ·',
      title: 'Paiement\nséquestré.',
      accent: 'Vous ne payez qu\'après.',
      subtitle: 'Votre argent est bloqué chez Stripe jusqu\'à votre validation. Aucune mauvaise surprise.',
      emoji: '🔒',
      color: AppColors.green,
    ),
    _OnboardingData(
      tag: '·RAPIDITÉ·',
      title: 'Réponse en\n30 minutes.',
      accent: 'Délai médian : 28 min.',
      subtitle: 'Sur les catégories Tech, Musique et Transport, la majorité des demandes reçoivent une offre en moins de 15 minutes.',
      emoji: '⚡',
      color: AppColors.amber,
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ── Grille de fond ───────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          // ── Glow amber ───────────────────────────────
          Positioned(
            top: -150, left: -100,
            child: Container(
              width: 500, height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.amber.withValues(alpha: 0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // ── Glow cyan ────────────────────────────────
          Positioned(
            bottom: -100, right: -150,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.cyan.withValues(alpha: 0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // ── Contenu ──────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      // Logo
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: AppColors.gradientAmber,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.bg,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SOS·BESOIN',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _finish,
                        child: const Text(
                          'Passer',
                          style: TextStyle(
                            color: AppColors.textMute,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (context, i) => _OnboardingPage(
                      data: _pages[i],
                    ),
                  ),
                ),
                // Indicateurs
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                        (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 28 : 8,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? _pages[_currentPage].color
                            : AppColors.line2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Bouton
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageCtrl.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _finish();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: AppColors.bg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage < _pages.length - 1
                                ? 'Suivant'
                                : 'Commencer',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage < _pages.length - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.check_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Données onboarding ────────────────────────────────────
class _OnboardingData {
  final String tag;
  final String title;
  final String accent;
  final String subtitle;
  final String emoji;
  final Color color;

  const _OnboardingData({
    required this.tag,
    required this.title,
    required this.accent,
    required this.subtitle,
    required this.emoji,
    required this.color,
  });
}

// ── Page onboarding ───────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: data.color.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              data.tag,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: data.color,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Emoji
          Text(
            data.emoji,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 24),
          // Titre
          Text(
            data.title,
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          // Accent
          Text(
            data.accent,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: data.color,
            ),
          ),
          const SizedBox(height: 16),
          // Sous-titre
          Text(
            data.subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textDim,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid painter ──────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}