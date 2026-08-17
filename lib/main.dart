import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_core/firebase_core.dart';
import 'core/notifications/notification_service.dart';
import 'core/services/payment_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    realtimeClientOptions: const RealtimeClientOptions(
      timeout: Duration(seconds: 30),
    ),
  );
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCk77lSKIwwLhP4ix7-0XJoi6LgoCVrsFE",
        authDomain: "sos-besoin.firebaseapp.com",
        projectId: "sos-besoin",
        storageBucket: "sos-besoin.firebasestorage.app",
        messagingSenderId: "379256786062",
        appId: "1:379256786062:web:4243e2df5d9efe80310ddf",
      ),
    );
  } catch (e) {
    debugPrint('Firebase already initialized: $e');
  }
  await NotificationService.init();
  await initOnboarding();

  if (!kIsWeb) {
    const stripeKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
    debugPrint("STRIPE KEY USED: $stripeKey");
    PaymentService.init(stripeKey);
  }

  timeago.setLocaleMessages('fr', timeago.FrMessages());
  await initializeDateFormatting('fr_CA', null);

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr'),
      child: const ProviderScope(child: SosBesoinApp()),
    ),
  );
}

class SosBesoinApp extends ConsumerWidget {
  const SosBesoinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'SOS-BESOIN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}