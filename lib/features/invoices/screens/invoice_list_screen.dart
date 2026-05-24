import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../providers/invoice_provider.dart';
import '../models/invoice_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';

class InvoiceListScreen extends ConsumerWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState  = ref.watch(authProvider);
    final isProvider = authState.activeRole == UserRole.provider;
    final invoicesAsync = isProvider
        ? ref.watch(providerInvoicesProvider)
        : ref.watch(clientInvoicesProvider);

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
          'Factures',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: invoicesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (e, _) => Center(
          child: Text('Erreur: $e',
              style: const TextStyle(color: AppColors.red)),
        ),
        data: (invoices) => invoices.isEmpty
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 48, color: AppColors.textMute),
              const SizedBox(height: 16),
              const Text(
                'Aucune facture pour l\'instant',
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
                    ? 'Vos factures apparaîtront après\nchaque mission complétée.'
                    : 'Vos factures apparaîtront après\nchaque paiement.',
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
          padding: const EdgeInsets.all(20),
          itemCount: invoices.length,
          itemBuilder: (context, i) => _InvoiceCard(
            invoice: invoices[i],
            isProvider: isProvider,
            onTap: () => context.push(
              '/invoices/${invoices[i].id}',
            ),
          ),
        ),
      ),
    );
  }
}

// ── Carte facture ─────────────────────────────────────────
class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final bool isProvider;
  final VoidCallback onTap;

  const _InvoiceCard({
    required this.invoice,
    required this.isProvider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('d MMM yyyy', 'fr_CA');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line2),
        ),
        child: Row(
          children: [
            // Emoji catégorie
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  invoice.categoryEmoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.requestTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    invoice.invoiceNumber,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMute,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatter.format(invoice.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMute,
                    ),
                  ),
                ],
              ),
            ),
            // Montant + statut
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isProvider ? invoice.providerAmount.toStringAsFixed(0) : invoice.amount.toStringAsFixed(0)}\$',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isProvider
                        ? AppColors.green
                        : AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Payée',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.textMute,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}