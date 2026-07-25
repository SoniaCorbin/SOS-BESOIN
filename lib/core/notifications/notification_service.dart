import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

// ── Handler background ────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _client    = Supabase.instance.client;

// ── Initialisation ────────────────────────────────────
  static Future<void> init() async {
    if (kIsWeb) return; // notifications pas supportées sur web

    // Handler background
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);

    // Demander permission
    final settings = await _messaging.requestPermission(
      alert:       true,
      badge:       true,
      sound:       true,
      provisional: false,
    );

    debugPrint('Permission: ${settings.authorizationStatus}');

    // Récupérer le token FCM
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    // Sauvegarder le token dans Supabase
    if (token != null) {
      await _saveToken(token);
    }

    // Rafraîchir le token automatiquement
    _messaging.onTokenRefresh.listen(_saveToken);

    // Notifications en foreground
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground message: ${message.notification?.title}');
    });

    // Au démarrage de l'app, le token peut être récupéré AVANT que
    // l'utilisateur soit connecté (session pas encore restaurée, ou
    // écran de login). Dans ce cas _saveToken ci-dessus ne fait rien
    // (userId == null). On écoute donc les changements d'auth pour
    // sauvegarder le token dès qu'une session devient active
    // (connexion, inscription, restauration de session).
    _client.auth.onAuthStateChange.listen((data) async {
      if (data.session != null) {
        await _saveCurrentToken();
      }
    });
  }

  // ── Récupérer le token courant et le sauvegarder ─────
  static Future<void> _saveCurrentToken() async {
    if (kIsWeb) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }
    } catch (e) {
      debugPrint('Erreur récupération token FCM: $e');
    }
  }

  // ── Envoyer une notification ─────────────────────────
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Récupérer le token FCM de l'utilisateur
      final profile = await _client
          .from('profiles')
          .select('fcm_token')
          .eq('id', userId)
          .single();

      final token = profile['fcm_token'] as String?;
      if (token == null) return;

      // Appeler une Supabase Edge Function pour envoyer la notif
      await _client.functions.invoke('send-notification', body: {
        'token': token,
        'title': title,
        'body':  body,
        'data':  data ?? {},
      });
    } catch (e) {
      debugPrint('Erreur envoi notification: $e');
    }
  }
  // ── Sauvegarder token FCM ────────────────────────────
  static Future<void> _saveToken(String token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('profiles').update({
        'fcm_token': token,
      }).eq('id', userId);
      debugPrint('FCM token sauvegardé !');
    } catch (e) {
      debugPrint('Erreur sauvegarde token: $e');
    }
  }
}