import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_banco/core/constants/app.strings.dart';
import 'package:app_banco/core/theme/app.theme.dart';
import 'package:app_banco/core/router/app.router.dart';
import 'package:app_banco/features/auth/providers/auth.provider.dart';
import 'package:app_banco/features/accounts/providers/account.provider.dart';
import 'package:app_banco/features/transfers/providers/transfer.provider.dart';
import 'package:app_banco/features/notifications/providers/notification.provider.dart';

/// Widget raíz de AndesPay
/// Configura el MultiProvider global, el tema y el router
class SmartBankApp extends StatelessWidget {
  const SmartBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..listenToAuthState(),
        ),
        ChangeNotifierProvider(
          create: (_) => AccountProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => TransferProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),
        // Fase 5: Agregar QrPaymentProvider
      ],
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
