import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_banco/features/accounts/models/account.model.dart';
import 'package:app_banco/features/accounts/repositories/account.repository.dart';
import 'package:app_banco/features/transfers/models/transaction.model.dart';

enum AccountStatus { initial, loading, loaded, error }

/// Provider de cuenta de ahorros
/// Escucha el saldo en tiempo real y carga transacciones recientes
class AccountProvider extends ChangeNotifier {
  final AccountRepository _repository = AccountRepository();

  AccountStatus _status = AccountStatus.initial;
  AccountModel? _account;
  List<TransactionModel> _recentTransactions = [];
  String? _errorMessage;
  StreamSubscription<AccountModel?>? _accountSub;

  // ── Getters ──

  AccountStatus get status => _status;
  AccountModel? get account => _account;
  List<TransactionModel> get recentTransactions => _recentTransactions;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AccountStatus.loading;
  bool get hasAccount => _account != null;

  // ── Inicialización ──

  /// Inicia la escucha en tiempo real de la cuenta del usuario
  Future<void> loadAccount(String userId) async {
    _setStatus(AccountStatus.loading);

    // Cancelar suscripción previa si existe
    await _accountSub?.cancel();

    _accountSub = _repository.watchAccount(userId).listen(
      (account) async {
        if (account == null) {
          // Primera vez: crear la cuenta de ahorros automáticamente
          try {
            final newAccount =
                await _repository.createSavingsAccount(userId);
            _account = newAccount;
          } catch (e) {
            _errorMessage = 'No se pudo crear la cuenta.';
            _setStatus(AccountStatus.error);
            return;
          }
        } else {
          _account = account;
        }
        // Cargar transacciones recientes
        await _loadRecentTransactions(userId);
        _setStatus(AccountStatus.loaded);
      },
      onError: (e) {
        _errorMessage = 'Error al cargar la cuenta.';
        _setStatus(AccountStatus.error);
      },
    );
  }

  /// Carga las transacciones recientes (llamada manual o al iniciar)
  Future<void> _loadRecentTransactions(String userId) async {
    try {
      _recentTransactions = await _repository.getRecentTransactions(
        userId: userId,
        limit: 10,
      );
      notifyListeners();
    } catch (_) {
      // Silenciar errores de transacciones para no bloquear el dashboard
    }
  }

  /// Recarga forzada de transacciones (pull-to-refresh)
  Future<void> refreshTransactions(String userId) async {
    await _loadRecentTransactions(userId);
  }

  // ── Limpiar al cerrar sesión ──

  Future<void> clear() async {
    await _accountSub?.cancel();
    _accountSub = null;
    _account = null;
    _recentTransactions = [];
    _status = AccountStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _accountSub?.cancel();
    super.dispose();
  }

  void _setStatus(AccountStatus status) {
    _status = status;
    notifyListeners();
  }
}
