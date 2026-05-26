import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/role_select_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/requests/screens/request_create_screen.dart';
import '../../features/requests/screens/request_detail_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/invoices/screens/invoice_list_screen.dart';
import '../../features/invoices/screens/invoice_detail_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/chat/screens/conversations_screen.dart';
import '../../features/reports/screens/report_screen.dart';
import '../../features/legal/screens/legal_screen.dart';
import '../../features/admin/screens/admin_screen.dart';

// ── Routes nommées ───────────────────────────────────────
class AppRoutes {
  static const splash         = '/';
  static const login          = '/login';
  static const register       = '/register';
  static const roleSelect     = '/role-select';
  static const home           = '/home';
  static const requestCreate  = '/request/create';
  static const requestDetail  = '/request/:id';
  static const chat           = '/chat/:id';
  static const profile        = '/profile';
  static const history        = '/history';
  static const invoices       = '/invoices';
  static const invoiceDetail  = '/invoices/:id';
}

// ── Provider ─────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isAuth     = authState.user != null ||
          Supabase.instance.client.auth.currentSession != null;
      final isLoading  = authState.loading;
      final isOnAuth   = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.splash;

      if (isLoading) return null;
      if (!isAuth && !isOnAuth) return AppRoutes.login;
      if (isAuth && state.matchedLocation == AppRoutes.login) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.roleSelect,
        builder: (_, __) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.requestCreate,
        builder: (_, __) => const RequestCreateScreen(),
      ),
      GoRoute(
        path: AppRoutes.requestDetail,
        builder: (context, state) => RequestDetailScreen(
          requestId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) => ChatScreen(
          chatId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.invoices,
        builder: (_, __) => const InvoiceListScreen(),
      ),
      GoRoute(
        path: AppRoutes.invoiceDetail,
        builder: (context, state) => InvoiceDetailScreen(
          invoiceId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/conversations',
        builder: (_, __) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) => ReportScreen(
          reportedUserId: state.uri.queryParameters['userId'],
          requestId:      state.uri.queryParameters['requestId'],
          offerId:        state.uri.queryParameters['offerId'],
          messageId:      state.uri.queryParameters['messageId'],
        ),
      ),
      GoRoute(
        path: '/terms',
        builder: (_, __) => const LegalScreen(
          title: 'Conditions générales d\'utilisation',
          content: LegalContent.termsOfService,
        ),
      ),
      GoRoute(
        path: '/privacy',
        builder: (_, __) => const LegalScreen(
          title: 'Politique de confidentialité',
          content: LegalContent.privacyPolicy,
        ),
      ),
      GoRoute(
        path: '/refund',
        builder: (_, __) => const LegalScreen(
          title: 'Politique de remboursement',
          content: LegalContent.refundPolicy,
        ),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminScreen(),
      ),
    ],
  );
});