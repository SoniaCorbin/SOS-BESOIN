import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _nameCtrl      = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _loading        = false;
  bool _acceptTerms    = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez accepter les conditions d\'utilisation.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final error = await ref.read(authProvider.notifier).signUp(
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      context.go(AppRoutes.roleSelect);
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
            top: -100, right: -100,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.cyan.withValues(alpha: 0.14),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -150, left: -100,
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
          // ── Contenu ─────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Retour
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textDim,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Titre
                  const Text(
                    'Créer un compte.',
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
                    'Rejoignez le réseau SOS-BESOIN.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Formulaire
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Nom complet
                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(color: AppColors.text),
                          decoration: const InputDecoration(
                            labelText: 'Nom complet',
                            prefixIcon: Icon(Icons.person_outline_rounded,
                                color: AppColors.textMute),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Champ requis';
                            }
                            if (v.trim().length < 2) {
                              return 'Nom trop court';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
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
                          obscureText: _obscurePass,
                          style: const TextStyle(color: AppColors.text),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: AppColors.textMute),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textMute,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Champ requis';
                            if (v.length < 8) return 'Minimum 8 caractères';
                            if (!v.contains(RegExp(r'[A-Z]'))) {
                              return 'Au moins une majuscule';
                            }
                            if (!v.contains(RegExp(r'[0-9]'))) {
                              return 'Au moins un chiffre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Confirmation mot de passe
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscureConfirm,
                          style: const TextStyle(color: AppColors.text),
                          decoration: InputDecoration(
                            labelText: 'Confirmer le mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: AppColors.textMute),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textMute,
                              ),
                              onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Champ requis';
                            if (v != _passCtrl.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        // Conditions
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              onChanged: (v) =>
                                  setState(() => _acceptTerms = v ?? false),
                              activeColor: AppColors.amber,
                              checkColor: AppColors.bg,
                              side: const BorderSide(color: AppColors.line2),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textDim,
                                      height: 1.5,
                                    ),
                                    children: [
                                      TextSpan(text: 'J\'accepte les '),
                                      TextSpan(
                                        text: 'Conditions d\'utilisation',
                                        style: TextStyle(
                                          color: AppColors.amber,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: ' et la '),
                                      TextSpan(
                                        text: 'Politique de confidentialité',
                                        style: TextStyle(
                                          color: AppColors.amber,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        // Bouton inscription
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
                                : const Text('Créer mon compte'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Déjà un compte
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Déjà un compte ? ',
                              style: TextStyle(
                                color: AppColors.textDim,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go(AppRoutes.login),
                              child: const Text(
                                'Se connecter',
                                style: TextStyle(
                                  color: AppColors.amber,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}