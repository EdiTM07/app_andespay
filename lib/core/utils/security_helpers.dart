import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utilidades de seguridad para AndesPay
/// El PIN nunca se guarda ni transmite en texto plano
class SecurityHelpers {
  SecurityHelpers._();

  /// Genera un hash SHA-256 del PIN de 4 dígitos
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifica si un PIN ingresado coincide con el hash almacenado
  static bool verifyPin(String pin, String storedHash) {
    return hashPin(pin) == storedHash;
  }

  /// Sanitiza un email eliminando espacios y convirtiendo a minúsculas
  static String sanitizeEmail(String email) => email.trim().toLowerCase();
}
