/// Validaciones de formularios para AndesPay
class AppValidators {
  AppValidators._();

  /// Email válido
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio.';
    }
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value.trim())) {
      return 'Ingresa un correo válido.';
    }
    return null;
  }

  /// Contraseña mínima 6 caracteres
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    if (value.length < 6) {
      return 'Mínimo 6 caracteres.';
    }
    return null;
  }

  /// Confirmar contraseña
  /// Recibe un getter [getOriginal] que lee el valor de la contraseña
  /// en el momento exacto de la validación, no al construir el widget.
  static String? Function(String?) confirmPassword(
    String Function() getOriginal,
  ) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Confirma tu contraseña.';
      }
      if (value != getOriginal()) {
        return 'Las contraseñas no coinciden.';
      }
      return null;
    };
  }

  /// Nombre completo
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio.';
    }
    if (value.trim().length < 3) {
      return 'Ingresa tu nombre completo.';
    }
    return null;
  }

  /// Cédula ecuatoriana (10 dígitos, algoritmo de módulo 10)
  static String? cedulaEcuador(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Opcional
    final clean = value.trim();

    if (clean.length != 10) return 'La cédula debe tener 10 dígitos.';
    if (!RegExp(r'^\d{10}$').hasMatch(clean)) {
      return 'Solo se permiten números.';
    }

    final codigoProvincia = int.parse(clean.substring(0, 2));
    if (codigoProvincia < 1 || codigoProvincia > 24) {
      return 'Cédula inválida (código de provincia).';
    }

    // Algoritmo módulo 10
    final digits = clean.split('').map(int.parse).toList();
    final verificador = digits[9];
    var suma = 0;
    for (var i = 0; i < 9; i++) {
      var d = digits[i];
      if (i % 2 == 0) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      suma += d;
    }
    final residuo = suma % 10;
    final calculado = residuo == 0 ? 0 : 10 - residuo;
    if (calculado != verificador) return 'Número de cédula inválido.';

    return null;
  }

  /// PIN de 4 dígitos
  static String? pin(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu PIN.';
    if (value.length != 4) return 'El PIN debe tener 4 dígitos.';
    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'El PIN solo puede tener números.';
    }
    return null;
  }

  /// Monto monetario mayor a 0
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa un monto.';
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return 'Monto inválido.';
    if (parsed <= 0) return 'El monto debe ser mayor a \$0.00.';
    return null;
  }
}
