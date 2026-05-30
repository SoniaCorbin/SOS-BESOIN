import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class StripeOnboardingScreen extends ConsumerStatefulWidget {
  const StripeOnboardingScreen({super.key});

  @override
  ConsumerState<StripeOnboardingScreen> createState() =>
      _StripeOnboardingScreenState();
}

class _StripeOnboardingScreenState
    extends ConsumerState<StripeOnboardingScreen> {
  bool _loading = false;

  Future<void> _startOnboarding() async {
    setState(() => _loading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client.functions.invoke(
        'create-connect-account',
        body: {
          'userId': user.id,
          'email':  user.email,
        },
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      final url = response.data['url'] as String;

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user      = authState.user;
    final hasStripe = user?.stripeAccountId != null &&
        user!.stripeAccountId!.isNotEmpty;

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
          'Paiements',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Icône
            Center(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: hasStripe
                      ? AppColors.greenSoft
                      : AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  hasStripe
                      ? Icons.check_circle_rounded
                      : Icons.account_balance_rounded,
                  color: hasStripe
                      ? AppColors.green
                      : AppColors.amber,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                hasStripe
                    ? 'Compte de paiement actif !'
                    : 'Configurez vos paiements',
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                hasStripe
                    ? 'Vous recevrez vos paiements automatiquement\naprès chaque mission validée.'
                    : 'Pour recevoir vos paiements, vous devez\nconfigurer votre compte Stripe.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMute,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            if (!hasStripe) ...[
              // Étapes
              _StepItem(
                number: '1',
                title: 'Créer votre compte Stripe',
                desc: 'Connectez votre compte bancaire en toute sécurité.',
              ),
              const SizedBox(height: 16),
              _StepItem(
                number: '2',
                title: 'Vérifier votre identité',
                desc: 'Stripe vérifie votre identité pour sécuriser les paiements.',
              ),
              const SizedBox(height: 16),
              _StepItem(
                number: '3',
                title: 'Recevoir vos paiements',
                desc: '90% du montant transféré automatiquement après chaque mission.',
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _startOnboarding,
                  child: _loading
                      ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.bg,
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Configurer mes paiements',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (hasStripe) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Compte connecté',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.green,
                            ),
                          ),
                          Text(
                            'ID: ${user?.stripeAccountId ?? ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.green,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String title;
  final String desc;

  const _StepItem({
    required this.number,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.amberSoft,
            border: Border.all(color: AppColors.amber),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.amber,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMute,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}