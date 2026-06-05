import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_banco/core/constants/app.colors.dart';
import 'package:app_banco/core/utils/formatters.dart';
import 'package:app_banco/core/utils/security_helpers.dart';
import 'package:app_banco/core/utils/validators.dart';
import 'package:app_banco/core/widgets/smartbank_button.dart';
import 'package:app_banco/core/widgets/smartbank_text_field.dart';
import 'package:app_banco/features/accounts/providers/account.provider.dart';
import 'package:app_banco/features/auth/providers/auth.provider.dart';
import 'package:app_banco/features/transfers/providers/transfer.provider.dart';

/// Confirmación de pago QR
/// Si el QR traía un monto fijo, muestra el monto.
/// Si era libre, permite al usuario ingresar el monto.
class QrPaymentConfirmPage extends StatefulWidget {
  final double initialAmount;
  final bool hasFixedAmount;
  final String? concept;

  const QrPaymentConfirmPage({
    super.key,
    required this.initialAmount,
    required this.hasFixedAmount,
    this.concept,
  });

  @override
  State<QrPaymentConfirmPage> createState() => _QrPaymentConfirmPageState();
}

class _QrPaymentConfirmPageState extends State<QrPaymentConfirmPage> {
  final _amountController = TextEditingController();
  final _conceptController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _pin = '';
  static const int _pinLength = 4;
  bool _pinError = false;
  bool _showForm = true;
  bool _showPin = false;

  @override
  void initState() {
    super.initState();
    if (widget.hasFixedAmount && widget.initialAmount > 0) {
      _amountController.text = widget.initialAmount.toStringAsFixed(2);
    }
    _conceptController.text = widget.concept ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _conceptController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;

    final myAccount = context.read<AccountProvider>().account;
    if (myAccount != null && amount > myAccount.balance) {
      _showSnackbar('Saldo insuficiente.', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    final hasPinConfigured =
        context.read<AuthProvider>().currentUser?.pinHash?.isNotEmpty ?? false;

    setState(() {
      _showForm = false;
      _showPin = hasPinConfigured;
    });

    if (!hasPinConfigured) {
      _executePayment();
    }
  }

  void _onKeyTap(String digit) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += digit;
        _pinError = false;
      });
      if (_pin.length == _pinLength) _verifyPin();
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

  Future<void> _verifyPin() async {
    final storedHash = context.read<AuthProvider>().currentUser?.pinHash;
    if (storedHash != null && storedHash.isNotEmpty) {
      if (!SecurityHelpers.verifyPin(_pin, storedHash)) {
        setState(() {
          _pin = '';
          _pinError = true;
        });
        return;
      }
    }
    await _executePayment();
  }

  Future<void> _executePayment() async {
    final auth = context.read<AuthProvider>();
    final accountProv = context.read<AccountProvider>();
    final transfer = context.read<TransferProvider>();
    final myAccount = accountProv.account;
    final myUser = auth.currentUser;
    if (myAccount == null || myUser == null) return;

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

    final success = await transfer.executeTransfer(
      fromAccount: myAccount,
      fromUser: myUser,
      amount: amount,
      concept: _conceptController.text.trim().isEmpty
          ? 'Pago QR AndesPay'
          : _conceptController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      accountProv.loadAccount(myUser.uid);
      context.go('/transfer-success');
    } else {
      _showSnackbar(
          transfer.errorMessage ?? 'Error al procesar el pago.', isError: true);
      setState(() {
        _pin = '';
        _showPin = false;
        _showForm = true;
      });
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transfer = context.watch<TransferProvider>();
    final myAccount = context.watch<AccountProvider>().account;
    final recipient = transfer.recipientUser;
    final recipientAccount = transfer.recipientAccount;

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
        title: Text(
          'Pago QR',
          style: GoogleFonts.poppins(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Destinatario ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (recipient?.fullName[0] ?? 'D').toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipient?.fullName ?? 'Destinatario',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        AppFormatters.accountNumber(
                            recipientAccount?.accountNumber ?? ''),
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.qr_code_rounded,
                      color: Colors.white, size: 24),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Formulario de monto ──
            if (_showForm)
              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Saldo disponible',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                          Text(
                            AppFormatters.currency(
                                myAccount?.balance ?? 0.0),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Campo monto
                      TextFormField(
                        controller: _amountController,
                        readOnly: widget.hasFixedAmount,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          final err = AppValidators.amount(v);
                          if (err != null) return err;
                          final parsed =
                              double.tryParse(v!.replaceAll(',', '.'));
                          if (parsed != null && parsed > (myAccount?.balance ?? 0)) {
                            return 'Saldo insuficiente.';
                          }
                          return null;
                        },
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: widget.hasFixedAmount
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          prefixStyle: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          hintText: '0.00',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.3),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          suffixIcon: widget.hasFixedAmount
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Fijo',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.warning,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),

                      const Divider(height: 24, color: Color(0xFFF0F0F0)),

                      SmartBankTextField(
                        label: 'Concepto',
                        controller: _conceptController,
                        prefixIcon: Icons.comment_outlined,
                        textInputAction: TextInputAction.done,
                        maxLength: 60,
                      ),

                      const SizedBox(height: 12),

                      SmartBankButton(
                        label: 'Confirmar pago',
                        isLoading: transfer.isProcessing,
                        onPressed: _onContinue,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ],
                  ),
                ),
              ),

            // ── Verificación PIN ──
            if (_showPin)
              _PinSection(
                pin: _pin,
                pinLength: _pinLength,
                hasError: _pinError,
                isLoading: transfer.isProcessing,
                onKeyTap: _onKeyTap,
                onDelete: _onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

// Sección de PIN compacta (reutilizable)
class _PinSection extends StatelessWidget {
  final String pin;
  final int pinLength;
  final bool hasError;
  final bool isLoading;
  final void Function(String) onKeyTap;
  final VoidCallback onDelete;

  const _PinSection({
    required this.pin,
    required this.pinLength,
    required this.hasError,
    required this.isLoading,
    required this.onKeyTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
                ),
              );
            }),
          ),
          if (hasError) ...[
            const SizedBox(height: 8),
            Text('PIN incorrecto',
                style: GoogleFonts.poppins(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
          const SizedBox(height: 20),
          if (isLoading)
            const CircularProgressIndicator(color: AppColors.primary)
          else
            _Keypad(onKeyTap: onKeyTap, onDelete: onDelete),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String) onKeyTap;
  final VoidCallback onDelete;
  const _Keypad({required this.onKeyTap, required this.onDelete});

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
                  .map((d) => _Key(digit: d, onTap: () => onKeyTap(d)))
                  .toList(),
            )),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 60, height: 60),
            _Key(digit: '0', onTap: () => onKeyTap('0')),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.backspace_outlined,
                    color: AppColors.error, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;
  const _Key({required this.digit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
