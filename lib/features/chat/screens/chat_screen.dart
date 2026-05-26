import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

// ── Providers ─────────────────────────────────────────────
final _client = Supabase.instance.client;

final messagesProvider = StreamProvider.family<List<Map<String, dynamic>>, String>(
      (ref, offerId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('offer_id', offerId)
        .order('created_at')
        .map((data) => List<Map<String, dynamic>>.from(data));
  },
);

final offerDetailProvider =
FutureProvider.family<Map<String, dynamic>, String>((ref, offerId) async {
  final data = await _client
      .from('offers')
      .select('*, requests(title, client_id), profiles!provider_id(full_name)')
      .eq('id', offerId)
      .single();
  return Map<String, dynamic>.from(data);
});

// ── Screen ────────────────────────────────────────────────
class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl      = TextEditingController();
  final _scrollCtrl   = ScrollController();
  bool _sending       = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      await _client.from('messages').insert({
        'offer_id':  widget.chatId,
        'sender_id': _client.auth.currentUser?.id,
        'content':   text,
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }

    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync  = ref.watch(messagesProvider(widget.chatId));
    final offerAsync     = ref.watch(offerDetailProvider(widget.chatId));
    final currentUserId  = _client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDim, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: offerAsync.when(
          loading: () => const Text(
            'Chargement...',
            style: TextStyle(color: AppColors.textDim, fontSize: 16),
          ),
          error: (_, __) => const Text('Chat'),
          data: (offer) {
            final request = offer['requests'] as Map<String, dynamic>?;
            final title   = request?['title'] as String? ?? 'Chat';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  '● En ligne',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.green,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined,
                color: AppColors.textDim),
            onPressed: () => context.push(
              '/report?offerId=${widget.chatId}',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded,
                color: AppColors.textDim),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ─────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.amber),
              ),
              error: (e, _) => Center(
                child: Text('Erreur: $e',
                    style: const TextStyle(color: AppColors.red)),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 48, color: AppColors.textMute),
                        SizedBox(height: 12),
                        Text(
                          'Commencez la conversation !',
                          style: TextStyle(
                            color: AppColors.textMute,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg      = messages[i];
                    final isMe     = msg['sender_id'] == currentUserId;
                    final content  = msg['content'] as String;
                    final sentAt   = DateTime.parse(
                        msg['created_at'] as String);

                    // Afficher date si premier message ou
                    // plus de 5 min d'écart
                    final showDate = i == 0 ||
                        sentAt
                            .difference(DateTime.parse(
                            messages[i - 1]['created_at'] as String))
                            .inMinutes >
                            5;

                    return Column(
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            child: Text(
                              timeago.format(sentAt, locale: 'fr'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMute,
                              ),
                            ),
                          ),
                        _MessageBubble(
                          content: content,
                          isMe: isMe,
                          sentAt: sentAt,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // ── Input ─────────────────────────────────────
          _ChatInput(
            controller: _msgCtrl,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ── Bulle de message ──────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final DateTime sentAt;

  const _MessageBubble({
    required this.content,
    required this.isMe,
    required this.sentAt,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.amber : AppColors.surface2,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? AppColors.amber.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? AppColors.bg : AppColors.text,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${sentAt.hour.toString().padLeft(2, '0')}:'
                  '${sentAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? AppColors.bg.withValues(alpha: 0.6)
                    : AppColors.textMute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Input chat ────────────────────────────────────────────
class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Écrivez un message...',
                hintStyle: const TextStyle(
                    color: AppColors.textMute, fontSize: 14),
                filled: true,
                fillColor: AppColors.surface2,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                      color: AppColors.amber, width: 1.5),
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sending
                    ? AppColors.surface2
                    : AppColors.amber,
                boxShadow: sending
                    ? []
                    : [
                  BoxShadow(
                    color: AppColors.amber.withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: sending
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textMute,
                ),
              )
                  : const Icon(
                Icons.send_rounded,
                color: AppColors.bg,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}