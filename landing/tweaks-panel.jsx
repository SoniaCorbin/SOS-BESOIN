import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../../../core/widgets/archive_toggle.dart';

final _client = Supabase.instance.client;

// ── Toggle "Actifs / Archivés" pour la liste des conversations ────
final showArchivedConversationsProvider = StateProvider<bool>((ref) => false);

final conversationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authProvider);
  final showArchived = ref.watch(showArchivedConversationsProvider);
  final isProvider = authState.activeRole == UserRole.provider;

  final data = await _client
      .from('conversations')
      .select()
      .eq(isProvider ? 'archived_by_provider' : 'archived_by_client', showArchived)
      .order('last_message_at', ascending: false, nullsFirst: false);

  return List<Map<String, dynamic>>.from(data);
});

// ── Archiver / désarchiver une conversation ───────────────
// La vue 'conversations' est calculée à partir de la table 'offers' —
// on met donc à jour 'offers' directement (via offer_id).
Future<void> setConversationArchived(
    String offerId, bool isProvider, bool archived) async {
  final column = isProvider ? 'archived_by_provider' : 'archived_by_client';
  await _client
      .from('offers')
      .update({column: archived})
      .eq('id', offerId);
}

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState     = ref.watch(authProvider);
    final isProvider    = authState.activeRole == UserRole.provider;
    final convsAsync    = ref.watch(conversationsProvider);
    final currentUserId = _client.auth.currentUser?.id;
    final isArchivedView = ref.watch(showArchivedConversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(
          'messages_title'.tr(),
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: ArchiveToggle(provider: showArchivedConversationsProvider),
            ),
          ),
          Expanded(
            child: convsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (e, _) => Center(
          child: Text('${'chat_error'.tr()}$e',
              style: const TextStyle(color: AppColors.red)),
        ),
        data: (conversations) => conversations.isEmpty
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  isArchivedView
                      ? Icons.archive_outlined
                      : Icons.chat_bubble_outline_rounded,
                  size: 48, color: AppColors.textMute),
              const SizedBox(height: 16),
              Text(
                isArchivedView
                    ? 'conv_no_archived'.tr()
                    : 'conv_empty_title'.tr(),
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDim,
                ),
              ),
              if (!isArchivedView) ...[
                const SizedBox(height: 8),
                Text(
                  isProvider
                      ? 'conv_empty_provider'.tr()
                      : 'conv_empty_client'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMute,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
                ? conv['provider_name'] as String? ?? 'conv_provider_default'.tr()
                : conv['client_name'] as String? ?? 'conv_client_default'.tr();
            final lastMessage = conv['last_message'] as String?;
            final lastMsgAt   = conv['last_message_at'] != null
                ? DateTime.parse(conv['last_message_at'] as String)
                : null;
            final unread  = (conv['unread_count'] as num?)?.toInt() ?? 0;

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
                                  lastMessage ?? 'conv_start'.tr(),
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
                    IconButton(
                      onPressed: () => _toggleArchive(
                          context, ref, conv['offer_id'] as String,
                          isProvider, isArchivedView),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: Icon(
                        isArchivedView
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                        size: 16,
                        color: AppColors.textMute,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleArchive(BuildContext context, WidgetRef ref,
      String offerId, bool isProvider, bool currentlyArchived) async {
    await setConversationArchived(offerId, isProvider, !currentlyArchived);
    ref.invalidate(conversationsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentlyArchived
              ? 'conv_unarchived_snack'.tr()
              : 'conv_archived_snack'.tr()),
          backgroundColor: AppColors.surface2,
        ),
      );
    }
  }
}