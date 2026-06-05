import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:app_banco/app/app.shell.widget.dart';
import 'package:app_banco/features/auth/providers/auth.provider.dart';
import 'package:app_banco/features/welcome/welcome.page.dart';
import 'package:app_banco/features/auth/pages/login.page.dart';
import 'package:app_banco/features/auth/pages/register.page.dart';
import 'package:app_banco/features/auth/pages/pin_setup.page.dart';
import 'package:app_banco/features/dashboard/pages/dashboard.page.dart';
import 'package:app_banco/features/accounts/pages/account_detail.page.dart';
import 'package:app_banco/features/transfers/pages/transfer.page.dart';
import 'package:app_banco/features/transfers/pages/transfer_confirm.page.dart';
import 'package:app_banco/features/transfers/pages/transfer_success.page.dart';
import 'package:app_banco/features/qr_payments/pages/qr_scanner.page.dart';
import 'package:app_banco/features/qr_payments/pages/qr_generator.page.dart';
import 'package:app_banco/features/qr_payments/pages/qr_payment_confirm.page.dart';
import 'package:app_banco/features/notifications/pages/notifications.page.dart';
import 'package:app_banco/features/profile/pages/profile.page.dart';
import 'package:app_banco/features/profile/pages/profile_edit.page.dart';

/// Configuración de rutas de AndesPay con GoRouter
/// Utiliza StatefulShellRoute para el BottomNavigationBar persistente
class AppRouter {
  AppRouter._();

  static GoRouter get router => GoRouter(
        initialLocation: '/',
        debugLogDiagnostics: true,
        redirect: _authGuard,
        routes: [
          // ── Splash / Welcome (pública) ──
          GoRoute(
            path: '/',
            name: 'welcome',
            builder: (context, _) => const WelcomePage(),
          ),

          // ── Autenticación (rutas públicas) ──
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, _) => const LoginPage(),
          ),
          GoRoute(
            path: '/register',
            name: 'register',
            builder: (context, _) => const RegisterPage(),
          ),
          GoRoute(
            path: '/pin-setup',
            name: 'pin-setup',
            builder: (context, _) => const PinSetupPage(),
          ),

          // ── Shell con BottomNav (rutas autenticadas) ──
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) =>
                AppShell(navigationShell: shell),
            branches: [
              // Branch 0: Dashboard
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/dashboard',
                    name: 'dashboard',
                    builder: (context, _) => const DashboardPage(),
                  ),
                ],
              ),
              // Branch 1: Transferencias
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/transfer',
                    name: 'transfer',
                    builder: (context, _) => const TransferPage(),
                  ),
                ],
              ),
              // Branch 2: QR
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/qr-scanner',
                    name: 'qr-scanner',
                    builder: (context, _) => const QrScannerPage(),
                  ),
                ],
              ),
              // Branch 3: Notificaciones
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/notifications',
                    name: 'notifications',
                    builder: (context, _) => const NotificationsPage(),
                  ),
                ],
              ),
              // Branch 4: Perfil
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    name: 'profile',
                    builder: (context, _) => const ProfilePage(),
                  ),
                ],
              ),
            ],
          ),

          // ── Rutas de detalle (fuera del Shell, sin BottomNav) ──
          GoRoute(
            path: '/account-detail',
            name: 'account-detail',
            builder: (context, _) => const AccountDetailPage(),
          ),
          GoRoute(
            path: '/transfer-confirm',
            name: 'transfer-confirm',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return TransferConfirmPage(
                amount: extra['amount'] as double,
                concept: extra['concept'] as String?,
              );
            },
          ),
          GoRoute(
            path: '/transfer-success',
            name: 'transfer-success',
            builder: (context, _) => const TransferSuccessPage(),
          ),
          GoRoute(
            path: '/qr-generator',
            name: 'qr-generator',
            builder: (context, _) => const QrGeneratorPage(),
          ),
          GoRoute(
            path: '/qr-payment-confirm',
            name: 'qr-payment-confirm',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return QrPaymentConfirmPage(
                initialAmount: extra['amount'] as double,
                hasFixedAmount: extra['hasFixedAmount'] as bool,
                concept: extra['concept'] as String?,
              );
            },
          ),
          GoRoute(
            path: '/edit-profile',
            name: 'edit-profile',
            builder: (context, _) => const ProfileEditPage(),
          ),
        ],
      );



  /// Guard de autenticación
  static String? _authGuard(BuildContext context, GoRouterState state) {
    final auth = context.read<AuthProvider>();
    final isAuth = auth.isAuthenticated;
    final location = state.matchedLocation;

    const publicRoutes = ['/', '/login', '/register'];
    final isPublic = publicRoutes.contains(location);
    final isPinSetup = location == '/pin-setup';

    // Rutas protegidas: redirigir al login si no está autenticado
    if (!isAuth && !isPublic && !isPinSetup) return '/login';

    // Si ya está autenticado no puede volver a login/register
    if (isAuth &&
        (location == '/login' || location == '/register')) {
      return '/dashboard';
    }

    return null;
  }
}
