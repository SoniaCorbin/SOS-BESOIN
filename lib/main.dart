import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
 WidgetsFlutterBinding.ensureInitialized();

// — Orientation portrait seulement ———————————————————————
  await SystemChrome.setPrefferredOrientations({
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  });

// — Status bar transparente ———————————————————————————————
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUIOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

// — Supabase ——————————————————————————————————————————————————
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(
    const ProviderScope(
      child: SosBesoinApp(),
    ),
  );
}

class SosBesoinApp extends ConsumerWidget {
  const SosBesoinApp({super.key});

  @override
  widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'SOS-BESOIN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
