import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';

// ── Provider ──────────────────────────────────────────────
final _client = Supabase.instance.client;

final conversationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authProvider);

  final data = await _client
      .from('conversations')
      .select()
      .order('last_message_at', ascending: false, nullsFirst: false);

  return List<Map<String, dynamic>>.from(data);
});

// ── Screen ────────────────────────────────────────────────
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState      = ref.watch(authProvider);
    final isProvider     = authState.activeRole == UserRole.provider;
    final convsAsync     = ref.watch(conversationsProvider);
    final currentUserId  = _client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: convsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (e, _) => Center(
          child: Text('Erreur: $e',
              style: const TextStyle(color: AppColors.red)),
        ),
        data: (conversations) => conversations.isEmpty
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 48, color: AppColors.textMute),
              const SizedBox(height: 16),
              const Text(
                'Aucune conversation',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDim,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isProvider
                    ? 'Vos conversations apparaîtront\naprès qu\'une offre soit acceptée.'
                    : 'Vos conversations apparaîtront\naprès avoir accepté une offre.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMute,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          itemBuilder: (context, i) {
            final conv        = conversations[i];
            final isClient    = conv['client_id'] == currentUserId;
            final otherName   = isClient
                ? conv['provider_name'] as String? ?? 'Prestataire'
                : conv['client_name'] as String? ?? 'Client';
            final lastMessage = conv['last_message'] as String?;
            final lastMsgAt   = conv['last_message_at'] != null
                ? DateTime.parse(conv['last_message_at'] as String)
                : null;
            final unread      = (conv['unread_count'] as num?)?.toInt() ?? 0;
            final category    = conv['request_category'] as String? ?? '';

            final initials = otherName.split(' ').length >= 2
                ? '${otherName.split(' ')[0][0]}${otherName.split(' ')[1][0]}'.toUpperCase()
                : otherName.substring(0, 2).toUpperCase();

            return GestureDetector(
              onTap: () => context.push('/chat/${conv['offer_id']}'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: unread > 0
                        ? (isProvider ? AppColors.cyan : AppColors.amber)
                        : AppColors.line2,
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isProvider
                            ? const LinearGradient(
                            colors: [AppColors.amber, AppColors.amber2])
                            : const LinearGradient(
                            colors: [AppColors.cyan, AppColors.cyan2]),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.bg,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Infos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  otherName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: unread > 0
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                              if (lastMsgAt != null)
                                Text(
                                  timeago.format(lastMsgAt, locale: 'fr'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMute,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            conv['request_title'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textDim,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lastMessage ?? 'Démarrez la conversation...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: unread > 0
                                        ? AppColors.text
                                        : AppColors.textMute,
                                    fontWeight: unread > 0
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unread > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isProvider
                                        ? AppColors.cyan
                                        : AppColors.amber,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$unread',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.bg,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}