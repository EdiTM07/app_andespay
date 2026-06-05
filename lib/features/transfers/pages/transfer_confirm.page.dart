import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_banco/core/constants/app.colors.dart';
import 'package:app_banco/core/utils/formatters.dart';
import 'package:app_banco/core/utils/security_helpers.dart';
import 'package:app_banco/core/widgets/smartbank_button.dart';
import 'package:app_banco/features/accounts/providers/account.provider.dart';
import 'package:app_banco/features/auth/providers/auth.provider.dart';
import 'package:app_banco/features/transfers/providers/transfer.provider.dart';

/// Pantalla de confirmación de transferencia con verificación de PIN
class TransferConfirmPage extends StatefulWidget {
  final double amount;
  final String? concept;

  const TransferConfirmPage({
    super.key,
    required this.amount,
    this.concept,
  });

  @override
  State<TransferConfirmPage> createState() => _TransferConfirmPageState();
}

class _TransferConfirmPageState extends State<TransferConfirmPage> {
  String _pin = '';
  static const int _pinLength = 4;
  bool _pinError = false;

  void _onKeyTap(String digit) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += digit;
        _pinError = false;
      });
      if (_pin.length == _pinLength) _onConfirm();
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _pinError = false;
      });
    }
  }

  Future<void> _onConfirm() async {
    final auth = context.read<AuthProvider>();
    final storedHash = auth.currentUser?.pinHash;

    // Si tiene PIN configurado, verificar
    if (storedHash != null && storedHash.isNotEmpty) {
      final isValid = SecurityHelpers.verifyPin(_pin, storedHash);
      if (!isValid) {
        setState(() {
          _pin = '';
          _pinError = true;
        });
        return;
      }
    }

    // Ejecutar transferencia
    final transfer = context.read<TransferProvider>();
    final accountProv = context.read<AccountProvider>();
    final myAccount = accountProv.account;
    final myUser = auth.currentUser;

    if (myAccount == null || myUser == null) return;

    final success = await transfer.executeTransfer(
      fromAccount: myAccount,
      fromUser: myUser,
      amount: widget.amount,
      concept: widget.concept,
    );

    if (!mounted) return;

    if (success) {
      // Refrescar saldo local
      accountProv.loadAccount(myUser.uid);
      context.go('/transfer-success');
    } else {
      _showError(transfer.errorMessage ?? 'Error al procesar la transferencia.');
      setState(() => _pin = '');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transfer = context.watch<TransferProvider>();
    final auth = context.watch<AuthProvider>();
    final hasPinConfigured = auth.currentUser?.pinHash?.isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Confirmar transferencia',
            style: GoogleFonts.poppins(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Resumen de la transferencia ──
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.07),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Monto grande
                        Text(
                          'Enviarás',
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppFormatters.currency(widget.amount),
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const Divider(height: 32, color: Color(0xFFF0F0F0)),

                        // Destinatario
                        _SummaryRow(
                          icon: Icons.person_rounded,
                          label: 'Para',
                          value:
                              transfer.recipientUser?.fullName ?? 'Destinatario',
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          icon: Icons.account_balance_rounded,
                          label: 'Cuenta destino',
                          value: AppFormatters.accountNumber(
                              transfer.recipientAccount?.accountNumber ?? ''),
                        ),
                        if (widget.concept?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 12),
                          _SummaryRow(
                            icon: Icons.comment_outlined,
                            label: 'Concepto',
                            value: widget.concept!,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _SummaryRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Fecha',
                          value: AppFormatters.dateTime(DateTime.now()),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Verificación de PIN / Confirmar ──
                  if (hasPinConfigured)
                    _PinConfirmSection(
                      pin: _pin,
                      pinLength: _pinLength,
                      hasError: _pinError,
                      isLoading: transfer.isProcessing,
                      onKeyTap: _onKeyTap,
                      onDelete: _onDelete,
                    )
                  else
                    // Sin PIN configurado: botón directo
                    SmartBankButton(
                      label: 'Confirmar transferencia',
                      isLoading: transfer.isProcessing,
                      onPressed: _onConfirm,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            color: AppColors.primary.withValues(alpha: 0.7), size: 18),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Sección de PIN para confirmar ──
class _PinConfirmSection extends StatelessWidget {
  final String pin;
  final int pinLength;
  final bool hasError;
  final bool isLoading;
  final void Function(String) onKeyTap;
  final VoidCallback onDelete;

  const _PinConfirmSection({
    required this.pin,
    required this.pinLength,
    required this.hasError,
    required this.isLoading,
    required this.onKeyTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Ingresa tu PIN para confirmar',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),

        // Dots del PIN
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pinLength, (i) {
            final filled = i < pin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: filled ? 18 : 16,
              height: filled ? 18 : 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasError
                    ? AppColors.error
                    : (filled ? AppColors.primary : Colors.transparent),
                border: Border.all(
                  color: hasError
                      ? AppColors.error
                      : (filled
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.3)),
                  width: 2,
                ),
                boxShadow: filled && !hasError
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                        )
                      ]
                    : [],
              ),
            );
          }),
        ),

        const SizedBox(height: 8),

        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: hasError ? 1.0 : 0.0,
          child: Text(
            'PIN incorrecto. Intenta de nuevo.',
            style: GoogleFonts.poppins(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ),

        const SizedBox(height: 20),

        if (isLoading)
          const CircularProgressIndicator(color: AppColors.primary)
        else
          _MiniKeypad(onKeyTap: onKeyTap, onDelete: onDelete),
      ],
    );
  }
}

/// Teclado numérico compacto para el PIN de confirmación
class _MiniKeypad extends StatelessWidget {
  final void Function(String) onKeyTap;
  final VoidCallback onDelete;

  const _MiniKeypad({required this.onKeyTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      children: [
        ...rows.map((row) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row
                  .map((d) => _MiniKey(digit: d, onTap: () => onKeyTap(d)))
                  .toList(),
            )),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 64, height: 64),
            _MiniKey(digit: '0', onTap: () => onKeyTap('0')),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.backspace_outlined,
                    color: AppColors.error, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniKey extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;

  const _MiniKey({required this.digit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(digit,
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ),
      ),
    );
  }
}
