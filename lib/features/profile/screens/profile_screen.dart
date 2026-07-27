import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/geolocation_service.dart';
import '../../requests/providers/request_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  double? _latitude;
  double? _longitude;
  bool _locating   = false;
  int _maxDistanceKm = 50;
  Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameCtrl.text  = user?.fullName ?? '';
    _phoneCtrl.text = user?.phone ?? '';
    _latitude       = user?.latitude;
    _longitude      = user?.longitude;
    _maxDistanceKm  = user?.maxDistanceKm ?? 50;
    _selectedCategories = (user?.providerCategories ?? []).toSet();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_link_error'.tr())),
        );
      }
    }
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final position = await GeolocationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _latitude  = position.latitude;
        _longitude = position.longitude;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_location_error'.tr())),
        );
      }
    }
    setState(() => _locating = false);
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      await Supabase.instance.client.from('profiles').update({
        'full_name':       _nameCtrl.text.trim(),
        'phone':           _phoneCtrl.text.trim(),
        'latitude':        _latitude,
        'longitude':       _longitude,
        'max_distance_km': _maxDistanceKm,
        'provider_categories':
            _selectedCategories.isEmpty ? null : _selectedCategories.toList(),
      }).eq('id', userId!);

      await ref.read(authProvider.notifier).init();

      if (mounted) {
        setState(() { _editing = false; _loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile_updated'.tr()),
            backgroundColor: AppColors.green,
          ),
        );
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'chat_error'.tr()}$e')),
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
        title: Text(
          'profile_title'.tr(),
          style: const TextStyle(
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
              _editing ? 'profile_save'.tr() : 'profile_edit'.tr(),
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
              style: const TextStyle(fontSize: 14, color: AppColors.textMute),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isProvider ? AppColors.cyanSoft : AppColors.amberSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isProvider ? AppColors.cyan : AppColors.amber,
                ),
              ),
              child: Text(
                isProvider
                    ? 'profile_mode_provider'.tr()
                    : 'profile_mode_client'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isProvider ? AppColors.cyan : AppColors.amber,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                _ProfileStat(
                  label: 'profile_stat_rating'.tr(),
                  value: user?.rating.toStringAsFixed(1) ?? '—',
                  icon: Icons.star_rounded,
                  color: AppColors.amber,
                ),
                _ProfileStat(
                  label: 'profile_stat_missions'.tr(),
                  value: '${user?.totalMissions ?? 0}',
                  icon: Icons.task_alt_rounded,
                  color: AppColors.cyan,
                ),
                _ProfileStat(
                  label: 'KYC',
                  value: user?.isKycVerified == true
                      ? 'profile_stat_kyc_verified'.tr()
                      : 'profile_stat_kyc_pending'.tr(),
                  icon: Icons.verified_rounded,
                  color: user?.isKycVerified == true
                      ? AppColors.green
                      : AppColors.textMute,
                ),
              ],
            ),
            const SizedBox(height: 32),
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
                  Text(
                    'profile_personal_info'.tr(),
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _editing
                      ? TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      labelText: 'profile_full_name'.tr(),
                      prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.textMute),
                    ),
                  )
                      : _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'profile_full_name'.tr(),
                    value: user?.fullName ?? '—',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'profile_email'.tr(),
                    value: user?.email ?? '—',
                  ),
                  const SizedBox(height: 12),
                  _editing
                      ? TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      labelText: 'profile_phone'.tr(),
                      prefixIcon: const Icon(Icons.phone_outlined,
                          color: AppColors.textMute),
                    ),
                  )
                      : _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'profile_phone'.tr(),
                    value: user?.phone?.isNotEmpty == true
                        ? user!.phone!
                        : 'profile_phone_empty'.tr(),
                  ),
                  if (_editing) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _locating ? null : _useMyLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _latitude != null
                              ? AppColors.greenSoft
                              : AppColors.surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _latitude != null
                                ? AppColors.green
                                : AppColors.line2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _latitude != null
                                  ? Icons.check_circle_rounded
                                  : Icons.my_location_rounded,
                              size: 18,
                              color: _latitude != null
                                  ? AppColors.green
                                  : AppColors.textMute,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _locating
                                    ? 'profile_locating'.tr()
                                    : _latitude != null
                                    ? 'profile_location_saved'.tr()
                                    : 'profile_location_use'.tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _latitude != null
                                      ? AppColors.green
                                      : AppColors.textDim,
                                ),
                              ),
                            ),
                            if (_locating)
                              const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.amber),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (isProvider) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.radar_rounded,
                              size: 16, color: AppColors.textMute),
                          const SizedBox(width: 8),
                          Text(
                            'profile_work_radius'.tr(),
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textDim),
                          ),
                          const Spacer(),
                          Text(
                            _maxDistanceKm >= 500
                                ? 'profile_unlimited'.tr()
                                : '$_maxDistanceKm km',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cyan,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _maxDistanceKm.toDouble(),
                        min: 5,
                        max: 500,
                        divisions: 99,
                        activeColor: AppColors.cyan,
                        inactiveColor: AppColors.line2,
                        onChanged: (val) =>
                            setState(() => _maxDistanceKm = val.round()),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.category_outlined,
                              size: 16, color: AppColors.textMute),
                          const SizedBox(width: 8),
                          Text(
                            'profile_categories_label'.tr(),
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textDim),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedCategories.isEmpty
                            ? 'profile_categories_all'.tr()
                            : 'profile_categories_hint'.tr(),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMute),
                      ),
                      const SizedBox(height: 10),
                      Builder(builder: (context) {
                        final categoriesAsync =
                        ref.watch(categoriesProvider);
                        return categoriesAsync.when(
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                          data: (categories) => Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categories.map((cat) {
                              final isSelected =
                              _selectedCategories.contains(cat.slug);
                              return GestureDetector(
                                onTap: () => setState(() {
                                  if (isSelected) {
                                    _selectedCategories.remove(cat.slug);
                                  } else {
                                    _selectedCategories.add(cat.slug);
                                  }
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.cyanSoft
                                        : AppColors.surface2,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.cyan
                                          : AppColors.line2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(cat.emoji,
                                          style:
                                          const TextStyle(fontSize: 13)),
                                      const SizedBox(width: 6),
                                      Text(
                                        cat.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.cyan
                                              : AppColors.textDim,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                  Text(
                    'profile_active_mode'.tr(),
                    style: const TextStyle(
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
                          label: 'profile_client'.tr(),
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
                          label: 'profile_provider'.tr(),
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
            const SizedBox(height: 20),
            if (user?.isAdmin == true) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.amber),
                ),
                child: GestureDetector(
                  onTap: () => context.push('/admin'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings_rounded,
                            color: AppColors.amber, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'profile_admin_panel'.tr(),
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.amber),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: AppColors.amber),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (isProvider) ...[
              GestureDetector(
                onTap: () => context.push('/stripe-onboarding'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_rounded,
                          color: AppColors.cyan, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'profile_configure_payments'.tr(),
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.textMute),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
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
                    label: 'profile_terms'.tr(),
                    onTap: () =>
                        _launchUrl('https://app.sosbesoin.ca/terms'),
                  ),
                  const Divider(color: AppColors.line, height: 1),
                  _LegalButton(
                    icon: Icons.privacy_tip_outlined,
                    label: 'profile_privacy'.tr(),
                    onTap: () =>
                        _launchUrl('https://app.sosbesoin.ca/privacy'),
                  ),
                  const Divider(color: AppColors.line, height: 1),
                  _LegalButton(
                    icon: Icons.replay_outlined,
                    label: 'profile_refund'.tr(),
                    onTap: () =>
                        _launchUrl('https://app.sosbesoin.ca/refund'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () =>
                    ref.read(authProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text('profile_sign_out'.tr()),
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
                  fontSize: 11, color: AppColors.textMute),
            ),
          ],
        ),
      ),
    );
  }
}

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
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMute)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.text,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

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
          color: isActive
              ? color.withValues(alpha: 0.15)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : AppColors.line2,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 20,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textMute),
          ],
        ),
      ),
    );
  }
}