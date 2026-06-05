import 'dart:convert';

/// Modelo de datos codificados en el QR de AndesPay
/// El QR contiene un JSON con estos campos
class QrDataModel {
  static const String _appId = 'andespay';

  final String accountNumber;
  final String ownerName;
  final double? amount; // null = monto libre, >0 = monto fijo

  const QrDataModel({
    required this.accountNumber,
    required this.ownerName,
    this.amount,
  });

  bool get hasFixedAmount => amount != null && amount! > 0;

  /// Codifica el modelo a un String JSON para embeber en el QR
  String encode() {
    return jsonEncode({
      'app': _appId,
      'account': accountNumber,
      'name': ownerName,
      if (amount != null) 'amount': amount,
    });
  }

  /// Decodifica el String del QR escaneado
  /// Retorna null si el QR no es de AndesPay
  static QrDataModel? decode(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['app'] != _appId) return null;
      return QrDataModel(
        accountNumber: json['account'] as String,
        ownerName: json['name'] as String,
        amount: (json['amount'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => encode();
}
