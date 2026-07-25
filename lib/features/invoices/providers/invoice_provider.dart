import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice_model.dart';
import '../../auth/providers/auth_provider.dart';

final _client = Supabase.instance.client;

// ── Factures du client ────────────────────────────────────
final clientInvoicesProvider = FutureProvider<List<InvoiceModel>>((ref) async {
  ref.watch(authProvider);

  final userId = _client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await _client
      .from('invoices')
      .select()
      .eq('client_id', userId)
      .order('created_at', ascending: false);

  print('INVOICES DATA: $data');

  return (data as List)
      .map((e) => InvoiceModel.fromMap(e))
      .toList();
});

// ── Factures du prestataire ───────────────────────────────
final providerInvoicesProvider = FutureProvider<List<InvoiceModel>>((ref) async {
  ref.watch(authProvider);

  final userId = _client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await _client
      .from('invoices')
      .select()
      .eq('provider_id', userId)
      .order('created_at', ascending: false);

  return (data as List)
      .map((e) => InvoiceModel.fromMap(e))
      .toList();
});

// ── Revenu du prestataire pour le mois en cours ───────────
// Dérivé de providerInvoicesProvider : somme de providerAmount
// (montant net après frais de plateforme) pour les factures du
// mois calendaire courant.
final providerMonthlyRevenueProvider = Provider<AsyncValue<double>>((ref) {
  final invoicesAsync = ref.watch(providerInvoicesProvider);
  final now = DateTime.now();

  return invoicesAsync.whenData((invoices) => invoices
      .where((inv) =>
  inv.status == 'paid' &&
      inv.createdAt.year == now.year &&
      inv.createdAt.month == now.month)
      .fold<double>(0, (sum, inv) => sum + inv.providerAmount));
});