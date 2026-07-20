import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
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
  void initState() {
    super.initState();
    _passCtrl.addListener(() => setState(() {}));
  }

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
        SnackBar(content: Text('accept_terms_error'.tr())),
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textDim,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'register_title'.tr(),
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
                    'register_subtitle'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(color: AppColors.text),
                          decoration: InputDecoration(
                            labelText: 'full_name'.tr(),
                            prefixIcon: const Icon(Icons.person_outline_rounded,
                                color: AppColors.textMute),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'name_required'.tr();
                            if (v.trim().length < 2) return 'name_too_short'.tr();
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
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
                          obscureText: _obscurePass,
                          style: const TextStyle(color: AppColors.text),
                          decoration: InputDecoration(
                            labelText: 'password'.tr(),
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
                            if (v == null || v.isEmpty) return 'field_required'.tr();
                            if (v.length < 8) return 'password_min_8'.tr();
                            if (!v.contains(RegExp(r'[A-Z]'))) return 'password_uppercase'.tr();
                            if (!v.contains(RegExp(r'[a-z]'))) return 'pwd_lowercase'.tr();
                            if (!v.contains(RegExp(r'[0-9]'))) return 'password_number'.tr();
                            if (!v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) return 'pwd_special'.tr();
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        _PasswordStrengthIndicator(password: _passCtrl.text),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscureConfirm,
                          style: const TextStyle(color: AppColors.text),
                          decoration: InputDecoration(
                            labelText: 'confirm_password'.tr(),
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
                            if (v == null || v.isEmpty) return 'field_required'.tr();
                            if (v != _passCtrl.text) return 'passwords_no_match'.tr();
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
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
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textDim,
                                      height: 1.5,
                                    ),
                                    children: [
                                      TextSpan(text: 'accept_terms'.tr()),
                                      TextSpan(
                                        text: 'terms_of_use'.tr(),
                                        style: const TextStyle(
                                          color: AppColors.amber,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: 'and'.tr()),
                                      TextSpan(
                                        text: 'privacy_policy'.tr(),
                                        style: const TextStyle(
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
                                : Text('create_my_account'.tr()),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'already_account'.tr(),
                              style: const TextStyle(
                                color: AppColors.textDim,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go(AppRoutes.login),
                              child: Text(
                                'sign_in_link'.tr(),
                                style: const TextStyle(
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

// ── Widget indicateur force mot de passe ──────────────────
class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  @override
  Widget build(BuildContext context) {
    final criteria = [
      (label: 'pwd_min_8'.tr(),     met: password.length >= 8),
      (label: 'pwd_uppercase'.tr(), met: password.contains(RegExp(r'[A-Z]'))),
      (label: 'pwd_lowercase'.tr(), met: password.contains(RegExp(r'[a-z]'))),
      (label: 'pwd_number'.tr(),    met: password.contains(RegExp(r'[0-9]'))),
      (label: 'pwd_special'.tr(),   met: password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: criteria.map((c) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(
              c.met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 14,
              color: c.met ? AppColors.green : AppColors.textMute,
            ),
            const SizedBox(width: 6),
            Text(
              c.label,
              style: TextStyle(
                fontSize: 12,
                color: c.met ? AppColors.green : AppColors.textMute,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}