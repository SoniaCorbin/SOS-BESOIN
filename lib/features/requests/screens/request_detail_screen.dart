import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../models/request_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../../../core/services/payment_service.dart';
import '../../invoices/providers/invoice_provider.dart';
import '../../../../core/notifications/notification_service.dart';

final _client = Supabase.instance.client;

final requestDetailProvider =
StreamProvider.family<RequestModel, String>((ref, id) {
  return _client
      .from('requests')
      .stream(primaryKey: ['id'])
      .eq('id', id)
      .map((rows) {
        if (rows.isEmpty) throw Exception('Request not found');
        return RequestModel.fromMap(rows.first);
      });
});

// StreamProvider: le client voit les offres apparaître (et leur statut
// changer) en temps réel, sans avoir à quitter/revenir sur l'écran.
// (auparavant FutureProvider = un seul chargement au montage de l'écran)
final requestOffersProvider =
StreamProvider.family<List<Map<String, dynamic>>, String>((ref, id) {
  return _client
      .from('offers')
      .stream(primaryKey: ['id'])
      .eq('request_id', id)
      .asyncMap((offersData) async {
    final offers = List<Map<String, dynamic>>.from(offersData)
      ..sort((a, b) => (b['created_at'] as String)
          .compareTo(a['created_at'] as String));

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
    return offers;
  });
});

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
        title: Text(
          'request_detail_title'.tr(),
          style: const TextStyle(
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
          child: Text('${'chat_error'.tr()}$e',
              style: const TextStyle(color: AppColors.red)),
        ),
        data: (request) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _RequestCard(request: request),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: offersAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (offers) => Row(
                    children: [
                      Text(
                        'request_offers_received'.tr(),
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
            offersAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.amber),
                  ),
                ),
              ),
              error: (_, __) =>
              const SliverToBoxAdapter(child: SizedBox()),
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
                    child: Column(
                      children: [
                        const Icon(Icons.hourglass_empty_rounded,
                            size: 40, color: AppColors.textMute),
                        const SizedBox(height: 12),
                        Text(
                          'request_waiting_offers'.tr(),
                          style: const TextStyle(
                            color: AppColors.textMute,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'request_pros_will_respond'.tr(),
                          style: const TextStyle(
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
                      ref.invalidate(requestOffersProvider(requestId));
                      ref.invalidate(requestDetailProvider(requestId));
                    },
                    onWithdrawn: () {
                      ref.invalidate(requestOffersProvider(requestId));
                    },
                  ),
                  childCount: offers.length,
                ),
              ),
            ),
            if (isProvider &&
                request.status == 'open' &&
                request.clientId !=
                    Supabase.instance.client.auth.currentUser?.id)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: () => _showOfferSheet(context, ref),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text('request_submit_offer_btn'.tr()),
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
          ref.invalidate(requestOffersProvider(requestId));
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final RequestModel request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner =
        request.clientId == Supabase.instance.client.auth.currentUser?.id;
    final canManage = isOwner && request.status == 'open';

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
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.amberSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber,
                      letterSpacing: 0.5,
                    ),
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
                      : request.status == 'cancelled'
                      ? AppColors.redSoft
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status == 'open'
                      ? 'request_status_open'.tr()
                      : request.status == 'cancelled'
                      ? 'request_status_cancelled'.tr()
                      : request.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: request.status == 'open'
                        ? AppColors.green
                        : request.status == 'cancelled'
                        ? AppColors.red
                        : AppColors.textMute,
                  ),
                ),
              ),
              if (canManage) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.textMute, size: 20),
                  color: AppColors.surface2,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditSheet(context, ref);
                    } else if (value == 'cancel') {
                      _cancelRequest(context, ref);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined,
                              size: 16, color: AppColors.textDim),
                          const SizedBox(width: 8),
                          Text('request_edit_btn'.tr(),
                              style:
                              const TextStyle(color: AppColors.text)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          const Icon(Icons.cancel_outlined,
                              size: 16, color: AppColors.red),
                          const SizedBox(width: 8),
                          Text('request_cancel_btn'.tr(),
                              style: const TextStyle(color: AppColors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
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
          Consumer(
            builder: (context, ref, _) {
              final invoiceAsync =
              ref.watch(invoiceForRequestProvider(request.id));
              return invoiceAsync.maybeWhen(
                data: (invoice) => invoice == null
                    ? const SizedBox()
                    : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          context.push('/invoice/${invoice.id}'),
                      icon: const Icon(Icons.receipt_long_outlined,
                          size: 16),
                      label: Text('request_view_invoice_btn'.tr()),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.amber),
                    ),
                  ),
                ),
                orElse: () => const SizedBox(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditRequestSheet(
        request: request,
        onSaved: () {
          ref.invalidate(requestDetailProvider(request.id));
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _cancelRequest(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'request_cancel_dialog_title'.tr(),
          style: const TextStyle(
              color: AppColors.text, fontFamily: 'SpaceGrotesk'),
        ),
        content: Text(
          'request_cancel_dialog_content'.tr(),
          style: const TextStyle(color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr(),
                style: const TextStyle(color: AppColors.textMute)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: Text('request_cancel_confirm_btn'.tr()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('requests')
          .update({'status': 'cancelled'}).eq('id', request.id);

      ref.invalidate
        (requestDetailProvider(request.id));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('request_cancelled_snack'.tr()),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'chat_error'.tr()}$e')),
        );
      }
    }
  }

  String _urgencyLabel(String urgency) {
    switch (urgency) {
      case 'asap':     return 'request_urgency_asap'.tr();
      case 'today':    return 'request_urgency_today'.tr();
      case 'tomorrow': return 'request_urgency_tomorrow'.tr();
      case 'week':     return 'request_urgency_week'.tr();
      default:         return urgency;
    }
  }
}

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
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }
}

class _EditRequestSheet extends ConsumerStatefulWidget {
  final RequestModel request;
  final VoidCallback onSaved;

  const _EditRequestSheet({
    required this.request,
    required this.onSaved,
  });

  @override
  ConsumerState<_EditRequestSheet> createState() => _EditRequestSheetState();
}

class _EditRequestSheetState extends ConsumerState<_EditRequestSheet> {
  late final _titleCtrl =
  TextEditingController(text: widget.request.title);
  late final _descCtrl =
  TextEditingController(text: widget.request.description);
  late final _budgetCtrl = TextEditingController(
      text: widget.request.budget?.toStringAsFixed(0) ?? '');
  late String _urgency = widget.request.urgency;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().length < 10 ||
        _descCtrl.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('request_min_10'.tr())),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final budgetText = _budgetCtrl.text.trim();
      double? budget;
      if (budgetText.isNotEmpty) {
        budget = double.tryParse(budgetText);
        if (budget == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('request_budget_invalid'.tr())),
            );
            setState(() => _loading = false);
          }
          return;
        }
      }

      await _client.from('requests').update({
        'title':       _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'budget':      budget,
        'urgency':     _urgency,
      }).eq('id', widget.request.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('request_edit_saved'.tr()),
            backgroundColor: AppColors.green,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'chat_error'.tr()}$e')),
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
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                'request_edit_sheet_title'.tr(),
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'request_title_label'.tr(),
                  hintText: 'request_title_hint'.tr(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(color: AppColors.text),
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'request_desc_label'.tr(),
                  hintText: 'request_desc_hint'.tr(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'request_budget_label'.tr(),
                  hintText: 'request_budget_hint'.tr(),
                  prefixIcon: const Icon(Icons.attach_money_rounded,
                      color: AppColors.textMute),
                  suffixText: '\$',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'request_urgency_label'.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDim,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: kUrgencies.map((u) {
                  final isSelected = _urgency == u['id'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _urgency = u['id']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.amberSoft
                              : AppColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.amber
                                : AppColors.line2,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(u['emoji']!,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              u['label']!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? AppColors.amber
                                    : AppColors.textMute,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_loading) _save();
                  },
                  child: _loading
                      ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.bg,
                    ),
                  )
                      : Text('request_edit_save_btn'.tr()),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final bool isClient;
  final String requestId;
  final VoidCallback onAccepted;
  final VoidCallback onWithdrawn;

  const _OfferCard({
    required this.offer,
    required this.isClient,
    required this.requestId,
    required this.onAccepted,
    required this.onWithdrawn,
  });

  @override
  Widget build(BuildContext context) {
    final profile  = offer['profiles'] as Map<String, dynamic>?;
    final name     = profile?['full_name'] as String? ?? 'conv_provider_default'.tr();
    final missions = profile?['total_missions'] as int? ?? 0;
    final price    = (offer['price'] as num).toDouble();
    final message  = offer['message'] as String;
    final status   = offer['status'] as String;
    final createdAt = DateTime.parse(offer['created_at'] as String);

    final initials = name.split(' ').length >= 2
        ? '${name.split(' ')[0][0]}${name.split(' ')[1][0]}'.toUpperCase()
        : name.substring(0, 2).toUpperCase();

    final currentUserId = _client.auth.currentUser?.id;
    final isOwnOffer = !isClient && offer['provider_id'] == currentUserId;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status == 'accepted' ? AppColors.greenSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'accepted' ? AppColors.green : AppColors.line2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'offer_missions'.tr(namedArgs: {'count': '$missions'}),
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
              Flexible(
                child: Text(
                  '${price.toStringAsFixed(0)}\$',
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amber,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textDim,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 12, color: AppColors.textMute),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  offer['availability'] as String,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMute,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeago.format(createdAt, locale: 'fr'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMute,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push(
                '/report?userId=${offer['provider_id']}&offerId=${offer['id']}',
              ),
              icon: const Icon(Icons.flag_outlined,
                  size: 14, color: AppColors.textMute),
              label: Text(
                'offer_report'.tr(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMute,
                ),
              ),
            ),
          ),
          if (isOwnOffer && status == 'pending') ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditSheet(context),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: Text('offer_edit_btn'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDim,
                      side: const BorderSide(color: AppColors.line2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _withdrawOffer(context),
                    icon: const Icon(Icons.remove_circle_outline_rounded,
                        size: 15),
                    label: Text('offer_withdraw_btn'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
                    Text('offer_pay_accept'.tr(namedArgs: {
                      'price': price.toStringAsFixed(0)
                    })),
                  ],
                ),
              ),
            ),
          ],
          if (status == 'accepted') ...[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: AppColors.green),
                  const SizedBox(width: 6),
                  Text(
                    'offer_accepted'.tr(),
                    style: const TextStyle(
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
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: Text('offer_open_chat'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cyan,
                  side: const BorderSide(color: AppColors.cyan),
                ),
              ),
            ),
            if (isClient) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _validateMission(context),
                  icon: const Icon(Icons.verified_rounded, size: 16),
                  label: Text('offer_validate_mission'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.bg,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditOfferSheet(
        offer: offer,
        onSaved: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _withdrawOffer(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'offer_withdraw_dialog_title'.tr(),
          style: const TextStyle(
              color: AppColors.text, fontFamily: 'SpaceGrotesk'),
        ),
        content: Text(
          'offer_withdraw_dialog_content'.tr(),
          style: const TextStyle(color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr(),
                style: const TextStyle(color: AppColors.textMute)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: Text('offer_withdraw_confirm_btn'.tr()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _client.from('offers').delete().eq('id', offer['id'] as String);

      onWithdrawn();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('offer_withdrawn_snack'.tr()),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'chat_error'.tr()}$e')),
        );
      }
    }
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
          content: Text('payment_success'.tr(
              namedArgs: {'invoice': result.invoiceNumber ?? ''})),
          backgroundColor: AppColors.green,
        ),
      );
      onAccepted();
    } else if (result.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('payment_cancelled'.tr())),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'chat_error'.tr()}${result.error}')),
      );
    }
  }

  Future<void> _acceptOffer(BuildContext context) async {
    try {
      await _client
          .from('offers')
          .update({'status': 'accepted'}).eq('id', offer['id'] as String);

      await _client
          .from('requests')
          .update({'status': 'in_progress'}).eq('id', requestId);

      onAccepted();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('offer_accepted'.tr()),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'chat_error'.tr()}$e')),
        );
      }
    }
  }

  Future<void> _validateMission(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'validate_dialog_title'.tr(),
          style: const TextStyle(
              color: AppColors.text, fontFamily: 'SpaceGrotesk'),
        ),
        content: Text(
          'validate_dialog_content'.tr(),
          style: const TextStyle(color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr(),
                style: const TextStyle(color: AppColors.textMute)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
            ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            child: Text('validate_confirm_btn'.tr()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _client
          .from('offers')
          .update({'status': 'completed'}).eq('id', offer['id'] as String);

      await _client
          .from('requests')
          .update({'status': 'completed'}).eq('id', requestId);

      onAccepted();

      if (context.mounted) {
        await _showRatingDialog(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'chat_error'.tr()}$e')),
        );
      }
    }
  }

  Future<void> _showRatingDialog(BuildContext context) async {
    int selectedRating    = 0;
    final commentCtrl     = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'rating_dialog_title'.tr(),
            style: const TextStyle(
                color: AppColors.text, fontFamily: 'SpaceGrotesk'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'rating_dialog_content'.tr(),
                style:
                const TextStyle(color: AppColors.textDim, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => selectedRating = star),
                    child: Icon(
                      Icons.star_rounded,
                      size: 40,
                      color: star <= selectedRating
                          ? AppColors.amber
                          : AppColors.line2,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                style: const TextStyle(color: AppColors.text),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'rating_comment_hint'.tr(),
                  hintStyle:
                  const TextStyle(color: AppColors.textMute),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('rating_skip_btn'.tr(),
                  style: const TextStyle(color: AppColors.textMute)),
            ),
            ElevatedButton(
              onPressed: selectedRating == 0
                  ? null
                  : () async {
                await _submitRating(
                  rating: selectedRating,
                  comment: commentCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('rating_success'.tr()),
                      backgroundColor: AppColors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber),
              child: Text('rating_submit_btn'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating({
    required int rating,
    required String comment,
  }) async {
    try {
      await _client.from('ratings').insert({
        'request_id':  requestId,
        'offer_id':    offer['id'],
        'client_id':   _client.auth.currentUser?.id,
        'provider_id': offer['provider_id'],
        'rating':      rating,
        'comment':     comment.isEmpty ? null : comment,
      });

      final ratings = await _client
          .from('ratings')
          .select('rating')
          .eq('provider_id', offer['provider_id'] as String);

      if (ratings.isNotEmpty) {
        final avg = ratings
            .map((r) => r['rating'] as int)
            .reduce((a, b) => a + b) /
            ratings.length;
        await _client.from('profiles').update({
          'rating':         (avg * 10).round() / 10,
          'total_missions': ratings.length,
        }).eq('id', offer['provider_id'] as String);
      }
    } catch (e) {
      debugPrint('Erreur notation: $e');
    }
  }
}

class _EditOfferSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> offer;
  final VoidCallback onSaved;

  const _EditOfferSheet({
    required this.offer,
    required this.onSaved,
  });

  @override
  ConsumerState<_EditOfferSheet> createState() => _EditOfferSheetState();
}

class _EditOfferSheetState extends ConsumerState<_EditOfferSheet> {
  late final _priceCtrl = TextEditingController(
      text: (widget.offer['price'] as num).toDouble().toStringAsFixed(0));
  late final _messageCtrl =
  TextEditingController(text: widget.offer['message'] as String);
  late final _availCtrl =
  TextEditingController(text: widget.offer['availability'] as String);
  bool _loading = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _messageCtrl.dispose();
    _availCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_priceCtrl.text.isEmpty ||
        _messageCtrl.text.isEmpty ||
        _availCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('offer_all_fields_required'.tr())),
      );
      return;
    }

    final price = double.tryParse(_priceCtrl.text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('request_budget_invalid'.tr())),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _client.from('offers').update({
        'price':        price,
        'message':      _messageCtrl.text.trim(),
        'availability': _availCtrl.text.trim(),
      }).eq('id', widget.offer['id'] as String);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('offer_edit_saved'.tr()),
            backgroundColor: AppColors.green,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'chat_error'.tr()}$e')),
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
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                'offer_edit_sheet_title'.tr(),
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'offer_price_label'.tr(),
                  prefixIcon: const Icon(Icons.attach_money_rounded,
                      color: AppColors.textMute),
                  suffixText: '\$',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _availCtrl,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'offer_availability_label'.tr(),
                  hintText: 'offer_availability_hint'.tr(),
                  prefixIcon: const Icon(Icons.schedule_rounded,
                      color: AppColors.textMute),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageCtrl,
                style: const TextStyle(color: AppColors.text),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'offer_message_label'.tr(),
                  hintText: 'offer_message_hint'.tr(),
                  prefixIcon: const Icon(Icons.message_outlined,
                      color: AppColors.textMute),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_loading) _save();
                  },
                  child: _loading
                      ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.bg,
                    ),
                  )
                      : Text('offer_edit_save_btn'.tr()),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

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
        SnackBar(content: Text('offer_all_fields_required'.tr())),
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

      try {
        final req = await _client
            .from('requests')
            .select('client_id, title')
            .eq('id', widget.requestId)
            .single();
        await NotificationService.sendNotification(
          userId: req['client_id'] as String,
          title: 'notif_new_offer_title'.tr(),
          body: 'notif_new_offer_body'
              .tr(namedArgs: {'title': req['title'] as String}),
          data: {'request_id': widget.requestId},
        );
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('offer_submitted'.tr()),
            backgroundColor: AppColors.green,
          ),
        );
        widget.onSubmitted();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('23505')
            ? 'offer_duplicate'.tr()
            : '${'chat_error'.tr()}$e';
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
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
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                'offer_sheet_title'.tr(),
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'offer_price_label'.tr(),
                  prefixIcon: const Icon(Icons.attach_money_rounded,
                      color: AppColors.textMute),
                  suffixText: '\$',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _availCtrl,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'offer_availability_label'.tr(),
                  hintText: 'offer_availability_hint'.tr(),
                  prefixIcon: const Icon(Icons.schedule_rounded,
                      color: AppColors.textMute),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageCtrl,
                style: const TextStyle(color: AppColors.text),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'offer_message_label'.tr(),
                  hintText: 'offer_message_hint'.tr(),
                  prefixIcon: const Icon(Icons.message_outlined,
                      color: AppColors.textMute),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_loading) _submit();
                  },
                  child: _loading
                      ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.bg,
                    ),
                  )
                      : Text('offer_send_btn'.tr()),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}