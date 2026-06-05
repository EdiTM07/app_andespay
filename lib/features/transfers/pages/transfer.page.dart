import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_banco/core/constants/app.colors.dart';
import 'package:app_banco/core/utils/formatters.dart';
import 'package:app_banco/core/utils/validators.dart';
import 'package:app_banco/core/widgets/smartbank_button.dart';
import 'package:app_banco/core/widgets/smartbank_text_field.dart';
import 'package:app_banco/features/accounts/providers/account.provider.dart';
import 'package:app_banco/features/transfers/providers/transfer.provider.dart';

/// Pantalla de transferencia P2P — Paso 1: Destinatario / Paso 2: Monto
class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage>
    with SingleTickerProviderStateMixin {
  final _accountNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _conceptController = TextEditingController();
  final _amountFormKey = GlobalKey<FormState>();

  int _step = 0; // 0 = destinatario, 1 = monto

  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    // Limpiar estado previo al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransferProvider>().reset();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _accountNumberController.dispose();
    _amountController.dispose();
    _conceptController.dispose();
    super.dispose();
  }

  // Paso 1: buscar destinatario
  Future<void> _onSearch() async {
    final number = _accountNumberController.text.trim();
    if (number.length < 10) {
      _showSnackbar(
        'Ingresa un número de cuenta válido (10 dígitos).',
        isError: true,
      );
      return;
    }

    // No permitir transferirse a sí mismo
    final myAccount = context.read<AccountProvider>().account;
    if (myAccount != null &&
        number.replaceAll('-', '') == myAccount.accountNumber) {
      _showSnackbar(
        'No puedes transferirte a tu propia cuenta.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    await context.read<TransferProvider>().searchRecipient(number);

    if (!mounted) return;
    final prov = context.read<TransferProvider>();
    if (prov.status == TransferStatus.recipientNotFound) {
      _showSnackbar('No existe una cuenta con ese número.', isError: true);
    } else if (prov.status == TransferStatus.recipientFound) {
      _goToStep(1);
    }
  }

  // Paso 2: ir a confirmación
  void _onContinue() {
    if (!(_amountFormKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null) return;

    final myAccount = context.read<AccountProvider>().account;
    if (myAccount != null && amount > myAccount.balance) {
      _showSnackbar('Saldo insuficiente.', isError: true);
      return;
    }

    context.push(
      '/transfer-confirm',
      extra: {'amount': amount, 'concept': _conceptController.text.trim()},
    );
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _animController.reset();
    _animController.forward();
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
        ),
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

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          onPressed: () {
            if (_step == 1) {
              _goToStep(0);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          'Transferir',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _animController,
          child: _step == 0
              ? _StepRecipient(
                  controller: _accountNumberController,
                  isSearching: transfer.isSearching,
                  onSearch: _onSearch,
                )
              : _StepAmount(
                  formKey: _amountFormKey,
                  amountController: _amountController,
                  conceptController: _conceptController,
                  recipientName:
                      transfer.recipientUser?.fullName ?? 'Destinatario',
                  recipientAccount:
                      transfer.recipientAccount?.accountNumber ?? '',
                  availableBalance: myAccount?.balance ?? 0.0,
                  onContinue: _onContinue,
                ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// PASO 1: Ingresar número de cuenta del destinatario
// ──────────────────────────────────────────────────────────
class _StepRecipient extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onSearch;

  const _StepRecipient({
    required this.controller,
    required this.isSearching,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Indicador de paso
          _StepIndicator(current: 0),

          const SizedBox(height: 28),

          // Ícono
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            '¿A quién vas a transferir?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa el número de cuenta de 10 dígitos',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 32),

          // Campo número de cuenta
          Container(
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
              children: [
                SmartBankTextField(
                  label: 'Número de cuenta destino',
                  controller: controller,
                  prefixIcon: Icons.account_balance_rounded,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                ),
                const SizedBox(height: 16),
                SmartBankButton(
                  label: 'Buscar destinatario',
                  isLoading: isSearching,
                  onPressed: onSearch,
                  icon: Icons.search_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'El número de cuenta de AndesPay comienza con "22" y tiene 10 dígitos.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// PASO 2: Ingresar monto y concepto
// ──────────────────────────────────────────────────────────
class _StepAmount extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController conceptController;
  final String recipientName;
  final String recipientAccount;
  final double availableBalance;
  final VoidCallback onContinue;

  const _StepAmount({
    required this.formKey,
    required this.amountController,
    required this.conceptController,
    required this.recipientName,
    required this.recipientAccount,
    required this.availableBalance,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepIndicator(current: 1),

            const SizedBox(height: 24),

            // Tarjeta del destinatario
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
                        recipientName[0].toUpperCase(),
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
                        recipientName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        AppFormatters.accountNumber(recipientAccount),
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Formulario de monto
            Container(
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
                  // Saldo disponible
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saldo disponible',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        AppFormatters.currency(availableBalance),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Campo monto con símbolo $
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final err = AppValidators.amount(v);
                      if (err != null) return err;
                      final parsed = double.tryParse(v!.replaceAll(',', '.'));
                      if (parsed != null && parsed > availableBalance) {
                        return 'Saldo insuficiente.';
                      }
                      return null;
                    },
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
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
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                    ),
                  ),

                  const Divider(height: 24, color: Color(0xFFF0F0F0)),

                  // Campo concepto
                  SmartBankTextField(
                    label: 'Concepto (opcional)',
                    controller: conceptController,
                    prefixIcon: Icons.comment_outlined,
                    textInputAction: TextInputAction.done,
                    maxLength: 60,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SmartBankButton(
              label: 'Continuar',
              onPressed: onContinue,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

// Indicador de pasos visual
class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(2, (i) {
        final isActive = i == current;
        final isDone = i < current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isDone || isActive
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
        );
      }),
    );
  }
}
