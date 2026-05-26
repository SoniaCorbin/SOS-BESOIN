import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../models/request_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../../../core/services/payment_service.dart';

// ── Providers ─────────────────────────────────────────────
final _client = Supabase.instance.client;

final requestDetailProvider =
FutureProvider.family<RequestModel, String>((ref, id) async {
  final data = await _client
      .from('requests')
      .select()
      .eq('id', id)
      .single();
  return RequestModel.fromMap(data);
});

final requestOffersProvider =
FutureProvider.family<List<Map<String, dynamic>>, String>((ref, id) async {
  print('FETCHING OFFERS FOR: $id');
  try {
    // 1. Récupérer les offres
    final offersData = await _client
        .from('offers')
        .select()
        .eq('request_id', id)
        .order('created_at', ascending: false);

    final offers = List<Map<String, dynamic>>.from(offersData);

    // 2. Pour chaque offre, récupérer le profil du prestataire
    for (int i = 0; i < offers.length; i++) {
      final providerId = offers[i]['provider_id'] as String;
      try {
        final profile = await _client
            .from('profiles')
            .select('full_name, rating, total_missions, is_kyc_verified')
            .eq('id', providerId)
            .single();
        offers[i] = {...offers[i], 'profiles': profile};
      } catch (_) {
        offers[i] = {...offers[i], 'profiles': null};
      }
    }

    print('OFFRES RESULT: $offers');
    return offers;
  } catch (e) {
    print('OFFRES ERROR: $e');
    rethrow;
  }
});

// ── Screen ────────────────────────────────────────────────
class RequestDetailScreen extends ConsumerWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('REQUEST ID: $requestId');
    final requestAsync = ref.watch(requestDetailProvider(requestId));
    final offersAsync  = ref.watch(requestOffersProvider(requestId));
    final authState    = ref.watch(authProvider);
    final isProvider   = authState.activeRole == UserRole.provider;

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
          'Détail de la demande',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: requestAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (e, _) => Center(
          child: Text('Erreur: $e',
              style: const TextStyle(color: AppColors.red)),
        ),
        data: (request) => CustomScrollView(
          slivers: [
            // ── Détail demande ───────────────────────
            SliverToBoxAdapter(
              child: _RequestCard(request: request),
            ),
            // ── Offres reçues ────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: offersAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (offers) => Row(
                    children: [
                      Text(
                        'Offres reçues',
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amberSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${offers.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── Liste des offres ─────────────────────
            offersAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                        color: AppColors.amber),
                  ),
                ),
              ),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
              data: (offers) => offers.isEmpty
                  ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line2),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.hourglass_empty_rounded,
                            size: 40, color: AppColors.textMute),
                        SizedBox(height: 12),
                        Text(
                          'En attente d\'offres...',
                          style: TextStyle(
                            color: AppColors.textMute,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Les pros vont répondre sous peu.',
                          style: TextStyle(
                            color: AppColors.textMute,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  : SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, i) => _OfferCard(
                    offer: offers[i],
                    isClient: !isProvider,
                    requestId: requestId,
                    onAccepted: () {
                      ref.refresh(requestOffersProvider(requestId));
                      ref.refresh(requestDetailProvider(requestId));
                    },
                  ),
                  childCount: offers.length,
                ),
              ),
            ),
            // ── Bouton soumettre offre (pro) ─────────
            if (isProvider &&
                request.status == 'open' &&
                request.clientId != Supabase.instance.client.auth.currentUser?.id)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: () => _showOfferSheet(context, ref),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Soumettre une offre'),
                      ],
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  void _showOfferSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OfferSheet(
        requestId: requestId,
        onSubmitted: () {
          ref.refresh(requestOffersProvider(requestId));
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Carte détail demande ──────────────────────────────────
class _RequestCard extends StatelessWidget {
  final RequestModel request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge catégorie + statut
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amber,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: request.status == 'open'
                      ? AppColors.greenSoft
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status == 'open' ? '● Ouvert' : request.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: request.status == 'open'
                        ? AppColors.green
                        : AppColors.textMute,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Titre
          Text(
            request.title,
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          // Description
          Text(
            request.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDim,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.line),
          const SizedBox(height: 16),
          // Infos
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.location_on_outlined,
                label: request.neighborhood != null
                    ? '${request.neighborhood}, ${request.location}'
                    : request.location,
              ),
              _InfoChip(
                icon: Icons.access_time_rounded,
                label: _urgencyLabel(request.urgency),
              ),
              if (request.budget != null)
                _InfoChip(
                  icon: Icons.attach_money_rounded,
                  label: '${request.budget!.toStringAsFixed(0)}\$',
                  color: AppColors.amber,
                ),
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: timeago.format(request.createdAt, locale: 'fr'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _urgencyLabel(String urgency) {
    switch (urgency) {
      case 'asap':     return '🔴 Dès que possible';
      case 'today':    return '🟠 Aujourd\'hui';
      case 'tomorrow': return '🟡 Demain';
      case 'week':     return '🟢 Cette semaine';
      default:         return urgency;
    }
  }
}

// ── Info chip ─────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = AppColors.textDim,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: color),
        ),
      ],
    );
  }
}

// ── Carte offre ───────────────────────────────────────────
class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final bool isClient;
  final String requestId;
  final VoidCallback onAccepted;

  const _OfferCard({
    required this.offer,
    required this.isClient,
    required this.requestId,
    required this.onAccepted,
  });

  @override
  Widget build(BuildContext context) {
    final profile   = offer['profiles'] as Map<String, dynamic>?;
    final name      = profile?['full_name'] as String? ?? 'Prestataire';
    final rating    = (profile?['rating'] as num?)?.toDouble() ?? 0.0;
    final missions  = profile?['total_missions'] as int? ?? 0;
    final isKyc     = profile?['is_kyc_verified'] as bool? ?? false;
    final price     = (offer['price'] as num).toDouble();
    final message   = offer['message'] as String;
    final status    = offer['status'] as String;
    final createdAt = DateTime.parse(offer['created_at'] as String);

    final initials = name.split(' ').length >= 2
        ? '${name.split(' ')[0][0]}${name.split(' ')[1][0]}'.toUpperCase()
        : name.substring(0, 2).toUpperCase();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status == 'accepted'
            ? AppColors.greenSoft
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'accepted'
              ? AppColors.green
              : AppColors.line2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface2,
                  border: Border.all(color: AppColors.line2),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        if (isKyc) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              size: 14, color: AppColors.cyan),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 12, color: AppColors.amber),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textDim,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$missions missions',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMute,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Prix
              Text(
                '${price.toStringAsFixed(0)}\$',
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Message
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textDim,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          // Disponibilité + temps
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 12, color: AppColors.textMute),
              const SizedBox(width: 4),
              Text(
                offer['availability'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMute,
                ),
              ),
              const Spacer(),
              Text(
                timeago.format(createdAt, locale: 'fr'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMute,
                ),
              ),
            ],
          ),
          // Bouton signaler
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push(
                '/report?userId=${offer['provider_id']}&offerId=${offer['id']}',
              ),
              icon: const Icon(Icons.flag_outlined,
                  size: 14, color: AppColors.textMute),
              label: const Text(
                'Signaler',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMute,
                ),
              ),
            ),
          ),
          // Bouton accepter (client seulement)
          if (isClient && status == 'pending') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => _payAndAccept(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.bg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded, size: 16),
                    const SizedBox(width: 8),
                    Text('Payer ${price.toStringAsFixed(0)}\$ et accepter.'),
                  ],
                ),
              ),
            ),
          ],
          if (status == 'accepted') ...[
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 16, color: AppColors.green),
                  SizedBox(width: 6),
                  Text(
                    'Offre acceptée',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/chat/${offer['id']}'),
                icon: const Icon(Icons.chat_bubble_outline_rounded,
                    size: 16),
                label: const Text('Ouvrir le chat'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cyan,
                  side: const BorderSide(color: AppColors.cyan),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _payAndAccept(BuildContext context) async {
    final result = await PaymentService.processPayment(
      amount:     (offer['price'] as num).toDouble(),
      offerId:    offer['id'] as String,
      requestId:  requestId,
      providerId: offer['provider_id'] as String,
    );

    if (!context.mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Paiement réussi ! Facture ${result.invoiceNumber}'),
          backgroundColor: AppColors.green,
        ),
      );
      onAccepted();
    } else if (result.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paiement annulé.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${result.error}')),
      );
    }
  }

  Future<void> _acceptOffer(BuildContext context) async {
    try {
      await _client.from('offers').update(
        {'status': 'accepted'},
      ).eq('id', offer['id'] as String);

      print('OFFRE ACCEPTEE: ${offer['id']}');

      await _client.from('requests').update(
        {'status': 'in_progress'},
      ).eq('id', requestId);

      onAccepted();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Offre acceptée ! Le pro a été notifié.'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}

// ── Bottom sheet soumettre offre ──────────────────────────
class _OfferSheet extends ConsumerStatefulWidget {
  final String requestId;
  final VoidCallback onSubmitted;

  const _OfferSheet({
    required this.requestId,
    required this.onSubmitted,
  });

  @override
  ConsumerState<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends ConsumerState<_OfferSheet> {
  final _priceCtrl   = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _availCtrl   = TextEditingController();
  bool _loading      = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _messageCtrl.dispose();
    _availCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_priceCtrl.text.isEmpty ||
        _messageCtrl.text.isEmpty ||
        _availCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez tous les champs.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final userId = _client.auth.currentUser?.id;
      await _client.from('offers').insert({
        'request_id':   widget.requestId,
        'provider_id':  userId,
        'price':        double.parse(_priceCtrl.text),
        'message':      _messageCtrl.text.trim(),
        'availability': _availCtrl.text.trim(),
        'status':       'pending',
      });

      widget.onSubmitted();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Offre soumise !'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = (e.toString().contains('unique_offer') ||
            e.toString().contains('23505'))
            ? 'Vous avez déjà soumis une offre sur cette demande.'
            : 'Erreur: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Soumettre une offre',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 20),
            // Prix
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(
                labelText: 'Votre prix',
                prefixIcon: Icon(Icons.attach_money_rounded,
                    color: AppColors.textMute),
                suffixText: '\$',
              ),
            ),
            const SizedBox(height: 12),
            // Disponibilité
            TextFormField(
              controller: _availCtrl,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(
                labelText: 'Disponibilité',
                hintText: 'ex: Disponible ce soir à 19h',
                prefixIcon: Icon(Icons.schedule_rounded,
                    color: AppColors.textMute),
              ),
            ),
            const SizedBox(height: 12),
            // Message
            TextFormField(
              controller: _messageCtrl,
              style: const TextStyle(color: AppColors.text),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message au client',
                hintText: 'Décrivez votre approche...',
                prefixIcon: Icon(Icons.message_outlined,
                    color: AppColors.textMute),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
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
                    : const Text('Envoyer mon offre'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}