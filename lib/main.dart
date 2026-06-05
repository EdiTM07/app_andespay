import 'package:flutter/material.dart';
import 'package:app_banco/app/app.startup.dart';
import 'package:app_banco/app/app.widget.dart';

void main() async {
  // Inicializar Firebase y servicios
  await AppStartup.initialize();

  // Ejecutar la app
  runApp(const SmartBankApp());
}
