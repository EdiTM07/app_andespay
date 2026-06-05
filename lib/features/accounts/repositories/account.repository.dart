import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_banco/core/constants/app.firestore_collections.dart';
import 'package:app_banco/features/accounts/models/account.model.dart';
import 'package:app_banco/features/transfers/models/transaction.model.dart';
import 'package:app_banco/services/firestore_service.dart';

/// Repositorio de cuentas de ahorros
/// Gestiona operaciones sobre la colección [accounts] y [transactions]
class AccountRepository {
  AccountRepository._();

  static final AccountRepository _instance = AccountRepository._();
  factory AccountRepository() => _instance;

  final FirestoreService _db = FirestoreService();

  // ── Crear cuenta de ahorros al registrarse ──

  /// Genera un número de cuenta único de 10 dígitos y lo guarda en Firestore
  Future<AccountModel> createSavingsAccount(String userId) async {
    final accountNumber = _generateAccountNumber();
    final id = '${userId}_account';

    final account = AccountModel(
      id: id,
      userId: userId,
      accountNumber: accountNumber,
      balance: 0.0,
      createdAt: DateTime.now(),
    );

    await _db.setDocument(
      collection: AppCollections.accounts,
      docId: id,
      data: account.toJson(),
    );

    return account;
  }

  // ── Leer cuenta del usuario actual ──

  /// Obtiene la cuenta de ahorros de un usuario
  Future<AccountModel?> getAccountByUserId(String userId) async {
    final data = await _db.getDocument(
      collection: AppCollections.accounts,
      docId: '${userId}_account',
    );
    if (data == null) return null;
    return AccountModel.fromJson(data);
  }

  /// Stream en tiempo real de la cuenta
  Stream<AccountModel?> watchAccount(String userId) {
    return _db
        .watchDocument(
          collection: AppCollections.accounts,
          docId: '${userId}_account',
        )
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return AccountModel.fromJson(snap.data()!);
    });
  }

  // ── Obtener cuenta por número de cuenta (para transferencias) ──

  Future<AccountModel?> getAccountByNumber(String accountNumber) async {
    final results = await _db.getCollection(
      collection: AppCollections.accounts,
      whereField: 'accountNumber',
      whereValue: accountNumber,
      limit: 1,
    );
    if (results.isEmpty) return null;
    return AccountModel.fromJson(results.first);
  }

  // ── Transacciones del usuario ──

  /// Obtiene las últimas [limit] transacciones del usuario
  Future<List<TransactionModel>> getRecentTransactions({
    required String userId,
    int limit = 10,
  }) async {
    // Buscar como emisor
    final sentSnapshot = await FirebaseFirestore.instance
        .collection(AppCollections.transactions)
        .where('fromUserId', isEqualTo: userId)
        .get();

    // Buscar como receptor
    final receivedSnapshot = await FirebaseFirestore.instance
        .collection(AppCollections.transactions)
        .where('toUserId', isEqualTo: userId)
        .get();

    final all = <TransactionModel>[];

    for (final doc in sentSnapshot.docs) {
      all.add(TransactionModel.fromJson(doc.data(), currentUserId: userId));
    }
    for (final doc in receivedSnapshot.docs) {
      // Evitar duplicados (si el usuario se transfirió a sí mismo)
      if (!all.any((t) => t.id == doc.id)) {
        all.add(TransactionModel.fromJson(doc.data(), currentUserId: userId));
      }
    }

    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all.take(limit).toList();
  }

  /// Stream de transacciones en tiempo real
  Stream<List<TransactionModel>> watchRecentTransactions({
    required String userId,
    int limit = 10,
  }) {
    return FirebaseFirestore.instance
        .collection(AppCollections.transactions)
        .where('fromUserId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => TransactionModel.fromJson(d.data(), currentUserId: userId))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.take(limit).toList();
    });
  }

  // ── Helper privado ──

  /// Genera un número de cuenta de 10 dígitos único
  String _generateAccountNumber() {
    final rng = Random.secure();
    // Prefijo 22 (AndesPay) + 8 dígitos aleatorios
    final digits =
        List.generate(8, (_) => rng.nextInt(10)).join();
    return '22$digits';
  }
}
