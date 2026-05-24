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