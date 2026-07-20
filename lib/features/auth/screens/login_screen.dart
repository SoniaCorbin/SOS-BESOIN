import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;
  bool _loading    = false;

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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  // Toggle FR/EN
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16, right: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => context.setLocale(const Locale('fr')),
                            child: Text(
                              'FR',
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.locale.languageCode == 'fr'
                                    ? AppColors.amber
                                    : AppColors.textMute,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('|',
                                style: TextStyle(color: AppColors.textMute, fontSize: 13)),
                          ),
                          GestureDetector(
                            onTap: () => context.setLocale(const Locale('en')),
                            child: Text(
                              'EN',
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.locale.languageCode == 'en'
                                    ? AppColors.amber
                                    : AppColors.textMute,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                      Text(
                        'app_name'.tr(),
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'login_title'.tr(),
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'login_subtitle'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.text),
                          decoration: InputDecoration(
                            labelText: 'email'.tr(),
                            prefixIcon: const Icon(Icons.mail_outline_rounded,
                                color: AppColors.textMute),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'field_required'.tr();
                            if (!v.contains('@')) return 'email_invalid'.tr();
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(color: AppColors.text),
                          decoration: InputDecoration(
                            labelText: 'password'.tr(),
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
                            if (v == null || v.isEmpty) return 'field_required'.tr();
                            if (v.length < 6) return 'password_min'.tr();
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              'forgot_password'.tr(),
                              style: const TextStyle(
                                color: AppColors.amber,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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
                                : Text('sign_in'.tr()),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.line2)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or'.tr(),
                                style: const TextStyle(
                                  color: AppColors.textMute,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppColors.line2)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => context.push(AppRoutes.register),
                            child: Text('create_account'.tr()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'legal_notice'.tr(),
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