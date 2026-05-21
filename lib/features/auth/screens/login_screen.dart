import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _obscure     = true;
  bool _loading     = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final error = await ref.read(authProvider.notifier).signIn(
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ── Glows ───────────────────────────────────────
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
          // ── Contenu ─────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  // Logo
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: AppColors.gradientAmber,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.amber.withValues(alpha: 0.4),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.bg,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'SOS·BESOIN',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  // Titre
                  const Text(
                    'Bon retour.',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connectez-vous pour accéder à votre compte.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Formulaire
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.text),
                          decoration: const InputDecoration(
                            labelText: 'Adresse courriel',
                            prefixIcon: Icon(Icons.mail_outline_rounded,
                                color: AppColors.textMute),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Champ requis';
                            if (!v.contains('@')) return 'Courriel invalide';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Mot de passe
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(color: AppColors.text),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: AppColors.textMute),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textMute,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Champ requis';
                            if (v.length < 6) return 'Minimum 6 caractères';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Mot de passe oublié
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(
                                color: AppColors.amber,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Bouton connexion
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.bg,
                              ),
                            )
                                : const Text('Se connecter'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.line2)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'ou',
                                style: TextStyle(
                                  color: AppColors.textMute,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppColors.line2)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Bouton inscription
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => context.push(AppRoutes.register),
                            child: const Text('Créer un compte'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Mentions légales
                  Center(
                    child: Text(
                      'En continuant, vous acceptez nos Conditions d\'utilisation\net notre Politique de confidentialité.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMute,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}