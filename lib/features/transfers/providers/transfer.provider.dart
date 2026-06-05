import 'package:flutter/material.dart';
import 'package:app_banco/features/accounts/models/account.model.dart';
import 'package:app_banco/features/auth/models/user.model.dart';
import 'package:app_banco/features/transfers/models/transaction.model.dart';
import 'package:app_banco/features/transfers/repositories/transfer.repository.dart';

/// Estados del flujo de transferencia
enum TransferStatus {
  idle,
  searchingRecipient,
  recipientFound,
  recipientNotFound,
  processing,
  success,
  error,
}

/// Provider del flujo de transferencia P2P
class TransferProvider extends ChangeNotifier {
  final TransferRepository _repository = TransferRepository();

  TransferStatus _status = TransferStatus.idle;
  AccountModel? _recipientAccount;
  UserModel? _recipientUser;
  TransactionModel? _lastTransaction;
  String? _errorMessage;

  // ── Getters ──

  TransferStatus get status => _status;
  AccountModel? get recipientAccount => _recipientAccount;
  UserModel? get recipientUser => _recipientUser;
  TransactionModel? get lastTransaction => _lastTransaction;
  String? get errorMessage => _errorMessage;

  bool get isSearching => _status == TransferStatus.searchingRecipient;
  bool get isProcessing => _status == TransferStatus.processing;
  bool get hasRecipient => _status == TransferStatus.recipientFound;
  bool get isSuccess => _status == TransferStatus.success;

  // ── Buscar destinatario ──

  Future<void> searchRecipient(String accountNumber) async {
    _errorMessage = null;
    _recipientAccount = null;
    _recipientUser = null;
    _setStatus(TransferStatus.searchingRecipient);

    try {
      final result = await _repository.findRecipient(accountNumber);
      if (result == null) {
        _setStatus(TransferStatus.recipientNotFound);
      } else {
        _recipientAccount = result.account;
        _recipientUser = result.user;
        _setStatus(TransferStatus.recipientFound);
      }
    } catch (e) {
      _errorMessage = 'Error al buscar destinatario.';
      _setStatus(TransferStatus.error);
    }
  }

  // ── Ejecutar transferencia ──

  Future<bool> executeTransfer({
    required AccountModel fromAccount,
    required UserModel fromUser,
    required double amount,
    String? concept,
  }) async {
    if (_recipientAccount == null || _recipientUser == null) return false;

    _setStatus(TransferStatus.processing);
    _errorMessage = null;

    try {
      _lastTransaction = await _repository.executeTransfer(
        fromAccount: fromAccount,
        toAccount: _recipientAccount!,
        fromUser: fromUser,
        toUser: _recipientUser!,
        amount: amount,
        concept: concept,
      );
      _setStatus(TransferStatus.success);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setStatus(TransferStatus.error);
      return false;
    }
  }

  // ── Limpiar estado (para nueva transferencia) ──

  void reset() {
    _status = TransferStatus.idle;
    _recipientAccount = null;
    _recipientUser = null;
    _lastTransaction = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == TransferStatus.error) {
      _setStatus(TransferStatus.idle);
    }
  }

  void _setStatus(TransferStatus s) {
    _status = s;
    notifyListeners();
  }
}
