/// Tipos de transacción en AndesPay
enum TransactionType { credit, debit }

/// Estado de una transacción
enum TransactionStatus { pending, completed, failed }

/// Modelo de Transacción de AndesPay
class TransactionModel {
  final String id;
  final String fromAccountId;
  final String toAccountId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String currency;
  final String? concept;
  final TransactionType type; // Relativo al usuario actual
  final TransactionStatus status;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    this.currency = 'USD',
    this.concept,
    required this.type,
    this.status = TransactionStatus.completed,
    required this.createdAt,
  });

  bool get isCredit => type == TransactionType.credit;
  bool get isDebit => type == TransactionType.debit;

  factory TransactionModel.fromJson(Map<String, dynamic> json,
      {required String currentUserId}) {
    final isReceiver = json['toUserId'] == currentUserId;
    return TransactionModel(
      id: json['id'] as String,
      fromAccountId: json['fromAccountId'] as String,
      toAccountId: json['toAccountId'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      concept: json['concept'] as String?,
      type: isReceiver ? TransactionType.credit : TransactionType.debit,
      status: _parseStatus(json['status'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'currency': currency,
      'concept': concept,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static TransactionStatus _parseStatus(String? s) {
    switch (s) {
      case 'pending':
        return TransactionStatus.pending;
      case 'failed':
        return TransactionStatus.failed;
      default:
        return TransactionStatus.completed;
    }
  }
}
