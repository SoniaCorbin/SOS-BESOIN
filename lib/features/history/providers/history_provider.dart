import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import '../../auth/providers/auth_provider.dart';

final _client = Supabase.instance.client;

// ── Historique du client ──────────────────────────────────
final clientHistoryProvider = FutureProvider<List<TransactionModel>>((ref) async {
  ref.watch(authProvider);

  final userId = _client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await _client
      .from('transactions')
      .select()
      .eq('client_id', userId)
      .order('created_at', ascending: false);

  return (data as List)
      .map((e) => TransactionModel.fromMap(e))
      .toList();
});

// ── Historique du prestataire ─────────────────────────────
final providerHistoryProvider = FutureProvider<List<TransactionModel>>((ref) async {
  ref.watch(authProvider);

  final userId = _client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await _client
      .from('transactions')
      .select()
      .eq('provider_id', userId)
      .order('created_at', ascending: false);

  return (data as List)
      .map((e) => TransactionModel.fromMap(e))
      .toList();
});

// ── Stats du prestataire ──────────────────────────────────
final providerStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(authProvider);

  final userId = _client.auth.currentUser?.id;
  if (userId == null) return {};

  final data = await _client
      .from('transactions')
      .select()
      .eq('provider_id', userId)
      .eq('status', 'completed');

  final transactions = List<Map<String, dynamic>>.from(data);

  final totalEarned = transactions.fold<double>(
      0, (sum, t) => sum + (t['provider_amount'] as num).toDouble());

  final thisMonth = transactions.where((t) {
    final date = DateTime.parse(t['created_at'] as String);
    final now = DateTime.now();
    return date.month == now.month && date.year == now.year;
  }).fold<double>(
      0, (sum, t) => sum + (t['provider_amount'] as num).toDouble());

  return {
    'total_earned':    totalEarned,
    'this_month':      thisMonth,
    'total_missions':  transactions.length,
  };
});