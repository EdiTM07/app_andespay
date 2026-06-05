import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:app_banco/core/constants/app.firestore_collections.dart';
import 'package:app_banco/features/accounts/models/account.model.dart';
import 'package:app_banco/features/auth/models/user.model.dart';
import 'package:app_banco/features/transfers/models/transaction.model.dart';
import 'package:app_banco/services/firestore_service.dart';

/// Repositorio de transferencias P2P
/// Toda operación monetaria se ejecuta en una transacción atómica de Firestore
class TransferRepository {
  TransferRepository._();

  static final TransferRepository _instance = TransferRepository._();
  factory TransferRepository() => _instance;

  final FirestoreService _db = FirestoreService();
  final _uuid = const Uuid();

  // ── Buscar destinatario por número de cuenta ──

  /// Retorna la cuenta y el perfil del destinatario si existe
  Future<({AccountModel account, UserModel user})?> findRecipient(
      String accountNumber) async {
    // Buscar la cuenta por número
    final accounts = await _db.getCollection(
      collection: AppCollections.accounts,
      whereField: 'accountNumber',
      whereValue: accountNumber.replaceAll('-', '').trim(),
      limit: 1,
    );
    if (accounts.isEmpty) return null;

    final account = AccountModel.fromJson(accounts.first);

    // Obtener el perfil del dueño
    final userData = await _db.getDocument(
      collection: AppCollections.users,
      docId: account.userId,
    );
    if (userData == null) return null;

    return (account: account, user: UserModel.fromJson(userData));
  }

  // ── Ejecutar transferencia ──

  /// Realiza el débito del emisor y el crédito del receptor de forma atómica.
  /// Lanza una excepción con mensaje legible si algo falla.
  Future<TransactionModel> executeTransfer({
    required AccountModel fromAccount,
    required AccountModel toAccount,
    required UserModel fromUser,
    required UserModel toUser,
    required double amount,
    String? concept,
  }) async {
    // Validaciones previas
    if (amount <= 0) throw Exception('El monto debe ser mayor a \$0.00.');
    if (fromAccount.id == toAccount.id) {
      throw Exception('No puedes transferirte a tu propia cuenta.');
    }

    final transactionId = _uuid.v4();
    final now = DateTime.now();

    late TransactionModel result;

    await _db.runTransaction((tx) async {
      // Leer saldos actuales dentro de la transacción
      final fromRef = _db.docRef(
        collection: AppCollections.accounts,
        docId: fromAccount.id,
      );
      final toRef = _db.docRef(
        collection: AppCollections.accounts,
        docId: toAccount.id,
      );
      final txRef = FirebaseFirestore.instance
          .collection(AppCollections.transactions)
          .doc(transactionId);

      final fromSnap = await tx.get(fromRef);
      final toSnap = await tx.get(toRef);

      if (!fromSnap.exists) throw Exception('Cuenta de origen no encontrada.');
      if (!toSnap.exists) throw Exception('Cuenta de destino no encontrada.');

      final fromBalance = (fromSnap.data()!['balance'] as num).toDouble();
      final toBalance = (toSnap.data()!['balance'] as num).toDouble();

      if (fromBalance < amount) {
        throw Exception('Saldo insuficiente. Tu saldo es \$$fromBalance.');
      }

      // Débito → Crédito → Registro de transacción (todo atómico)
      tx.update(fromRef, {'balance': fromBalance - amount});
      tx.update(toRef, {'balance': toBalance + amount});

      final txData = {
        'id': transactionId,
        'fromAccountId': fromAccount.id,
        'toAccountId': toAccount.id,
        'fromUserId': fromUser.uid,
        'toUserId': toUser.uid,
        'amount': amount,
        'currency': 'USD',
        'concept': concept?.trim().isEmpty ?? true ? null : concept?.trim(),
        'status': 'completed',
        'createdAt': now.toIso8601String(),
      };
      tx.set(txRef, txData);

      result = TransactionModel(
        id: transactionId,
        fromAccountId: fromAccount.id,
        toAccountId: toAccount.id,
        fromUserId: fromUser.uid,
        toUserId: toUser.uid,
        amount: amount,
        concept: txData['concept'] as String?,
        type: TransactionType.debit,
        status: TransactionStatus.completed,
        createdAt: now,
      );
    });

    return result;
  }
}
