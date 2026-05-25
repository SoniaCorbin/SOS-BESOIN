import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  static final _client = Supabase.instance.client;

  static void init(String publishableKey) {
    Stripe.publishableKey = publishableKey;
  }

  static Future<PaymentResult> processPayment({
    required double amount,
    required String offerId,
    required String requestId,
    required String providerId,
  }) async {
    try {
      final clientId = _client.auth.currentUser?.id;
      if (clientId == null) {
        return PaymentResult.error('Utilisateur non connecté.');
      }

      // 1. Créer le Payment Intent
      final response = await _client.functions.invoke(
        'create-payment-intent',
        body: {
          'amount':     amount,
          'currency':   'cad',
          'offerId':    offerId,
          'clientId':   clientId,
          'providerId': providerId,
        },
      );

      if (response.data['error'] != null) {
        return PaymentResult.error(response.data['error']);
      }

      final clientSecret    = response.data['clientSecret'] as String;
      final paymentIntentId = response.data['paymentIntentId'] as String;

      // 2. Initialiser la feuille de paiement
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'SOS-BESOIN',
          style: ThemeMode.dark,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary:             Color(0xFFF59E0B),
              background:          Color(0xFF0B1220),
              componentBackground: Color(0xFF111C33),
              componentText:       Color(0xFFF1F5F9),
              placeholderText:     Color(0xFF64748B),
            ),
          ),
        ),
      );

      // 3. Afficher la feuille de paiement
      await Stripe.instance.presentPaymentSheet();

      print('STRIPE PAYMENT CONFIRMED - calling capture-payment');

      // 4. Capturer le paiement
      final captureResponse = await _client.functions.invoke(
        'capture-payment',
        body: {
          'paymentIntentId': paymentIntentId,
          'offerId':         offerId,
          'requestId':       requestId,
        },
      );

      print('CAPTURE RESPONSE: ${captureResponse.data}');
      print('CAPTURE STATUS: ${captureResponse.status}');

      if (captureResponse.data['error'] != null) {
        return PaymentResult.error(captureResponse.data['error']);
      }

      return PaymentResult.success(
        amount:         (captureResponse.data['amount'] as num).toDouble(),
        platformFee:    (captureResponse.data['platformFee'] as num).toDouble(),
        providerAmount: (captureResponse.data['providerAmount'] as num).toDouble(),
        invoiceNumber:  captureResponse.data['invoiceNumber'] as String,
      );

    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return PaymentResult.cancelled();
      }
      return PaymentResult.error(e.error.localizedMessage ?? 'Erreur Stripe');
    } catch (e) {
      print('PAYMENT ERROR: $e');
      return PaymentResult.error('Erreur: $e');
    }
  }
}

// ── Résultat du paiement ──────────────────────────────────
class PaymentResult {
  final bool success;
  final bool cancelled;
  final String? error;
  final double? amount;
  final double? platformFee;
  final double? providerAmount;
  final String? invoiceNumber;

  const PaymentResult._({
    required this.success,
    required this.cancelled,
    this.error,
    this.amount,
    this.platformFee,
    this.providerAmount,
    this.invoiceNumber,
  });

  factory PaymentResult.success({
    required double amount,
    required double platformFee,
    required double providerAmount,
    required String invoiceNumber,
  }) =>
      PaymentResult._(
        success:        true,
        cancelled:      false,
        amount:         amount,
        platformFee:    platformFee,
        providerAmount: providerAmount,
        invoiceNumber:  invoiceNumber,
      );

  factory PaymentResult.error(String message) => PaymentResult._(
    success:   false,
    cancelled: false,
    error:     message,
  );

  factory PaymentResult.cancelled() => const PaymentResult._(
    success:   false,
    cancelled: true,
  );
}