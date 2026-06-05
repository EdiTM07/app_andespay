import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:app_banco/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Inicialización de servicios de SmartBank EC
class AppStartup {
  AppStartup._();

  /// Inicializa Firebase y otros servicios necesarios
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('es', null);

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
