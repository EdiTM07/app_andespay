/// Modelo de Cuenta de Ahorros de AndesPay
class AccountModel {
  final String id;
  final String userId;
  final String accountNumber; // Número de 10 dígitos
  final double balance;
  final String currency; // 'USD'
  final bool isActive;
  final DateTime createdAt;

  const AccountModel({
    required this.id,
    required this.userId,
    required this.accountNumber,
    required this.balance,
    this.currency = 'USD',
    this.isActive = true,
    required this.createdAt,
  });

  String get accountType => 'Ahorros';

  /// Número de cuenta con formato: **** 1234
  String get maskedNumber =>
      '**** ${accountNumber.substring(accountNumber.length - 4)}';

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      accountNumber: json['accountNumber'] as String,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'accountNumber': accountNumber,
      'balance': balance,
      'currency': currency,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AccountModel copyWith({double? balance, bool? isActive}) {
    return AccountModel(
      id: id,
      userId: userId,
      accountNumber: accountNumber,
      balance: balance ?? this.balance,
      currency: currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
