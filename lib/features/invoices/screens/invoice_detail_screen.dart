import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/invoice_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';

// ── Provider ──────────────────────────────────────────────
final invoiceDetailProvider =
FutureProvider.family<InvoiceModel, String>((ref, id) async {
  final data = await Supabase.instance.client
      .from('invoices')
      .select()
      .eq('id', id)
      .single();
  return InvoiceModel.fromMap(data);
});

// ── Screen ────────────────────────────────────────────────
class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(invoiceDetailProvider(invoiceId));
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
          'Facture',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined,
                color: AppColors.textDim),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export PDF — à venir !'),
                ),
              );
            },
          ),
        ],
      ),
      body: invoiceAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (e, _) => Center(
          child: Text('Erreur: $e',
              style: const TextStyle(color: AppColors.red)),
        ),
        data: (invoice) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── En-tête facture ──────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line2),
                ),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: AppColors.gradientAmber,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.bg,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'SOS·BESOIN',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMute,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.greenSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✓ Payée',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ── Détails mission ──────────────────────
              _Section(
                title: 'Mission',
                children: [
                  _DetailRow(
                    label: 'Service',
                    value: invoice.requestTitle,
                  ),
                  _DetailRow(
                    label: 'Catégorie',
                    value: '${invoice.categoryEmoji} ${invoice.requestCategory}',
                  ),
                  _DetailRow(
                    label: 'Date',
                    value: DateFormat('d MMMM yyyy', 'fr_CA')
                        .format(invoice.createdAt),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Parties ──────────────────────────────
              _Section(
                title: 'Parties',
                children: [
                  _DetailRow(
                    label: 'Client',
                    value: invoice.clientName,
                  ),
                  _DetailRow(
                    label: 'Prestataire',
                    value: invoice.providerName,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Montants ─────────────────────────────
              _Section(
                title: 'Détail des montants',
                children: [
                  _DetailRow(
                    label: 'Montant total',
                    value: '${invoice.amount.toStringAsFixed(2)}\$',
                  ),
                  _DetailRow(
                    label: 'Commission plateforme (10%)',
                    value: '-${invoice.platformFee.toStringAsFixed(2)}\$',
                    valueColor: AppColors.red,
                  ),
                  const Divider(color: AppColors.line),
                  _DetailRow(
                    label: isProvider
                        ? 'Montant reçu'
                        : 'Montant payé',
                    value: isProvider
                        ? '+${invoice.providerAmount.toStringAsFixed(2)}\$'
                        : '${invoice.amount.toStringAsFixed(2)}\$',
                    valueColor: isProvider
                        ? AppColors.green
                        : AppColors.amber,
                    isBold: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // ── Bouton PDF ───────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Export PDF — à venir !'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Télécharger en PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.amber,
                    side: const BorderSide(color: AppColors.amber),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section ───────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            title,
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDim,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

// ── Detail row ────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textDim,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: valueColor ?? AppColors.text,
              fontFamily: isBold ? 'SpaceGrotesk' : null,
            ),
          ),
        ],
      ),
    );
  }
}