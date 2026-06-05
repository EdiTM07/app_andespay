import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:app_banco/core/constants/app.colors.dart';
import 'package:app_banco/core/utils/formatters.dart';
import 'package:app_banco/core/widgets/smartbank_button.dart';
import 'package:app_banco/core/widgets/smartbank_text_field.dart';
import 'package:app_banco/core/utils/validators.dart';
import 'package:app_banco/features/accounts/providers/account.provider.dart';
import 'package:app_banco/features/auth/providers/auth.provider.dart';
import 'package:app_banco/features/qr_payments/models/qr_data.model.dart';

/// Pantalla para generar el QR de cobro del usuario
class QrGeneratorPage extends StatefulWidget {
  const QrGeneratorPage({super.key});

  @override
  State<QrGeneratorPage> createState() => _QrGeneratorPageState();
}

class _QrGeneratorPageState extends State<QrGeneratorPage>
    with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showAmountField = false;
  double? _fixedAmount;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _applyAmount() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final parsed = double.tryParse(_amountController.text.replaceAll(',', '.'));
    setState(() => _fixedAmount = parsed);
    FocusScope.of(context).unfocus();
  }

  void _clearAmount() {
    setState(() {
      _fixedAmount = null;
      _amountController.clear();
      _showAmountField = false;
    });
  }

  void _copyAccountNumber(String number) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Número de cuenta copiado',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final accountProv = context.watch<AccountProvider>();
    final account = accountProv.account;
    final user = auth.currentUser;

    if (account == null || user == null) {
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
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final qrData = QrDataModel(
      accountNumber: account.accountNumber,
      ownerName: user.fullName,
      amount: _fixedAmount,
    ).encode();

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
          'Mi código QR',
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
            Text(
              _fixedAmount != null
                  ? 'Comparte este QR para cobrar\n${AppFormatters.currency(_fixedAmount!)}'
                  : 'Comparte este QR para recibir pagos',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            // ── Tarjeta QR ──
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar + nombre
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      user.fullName[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.fullName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AndesPay',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.primary),
                  ),

                  const SizedBox(height: 20),

                  // QR code
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          width: 2,
                        ),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF00695C),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF004D40),
                        ),
                        embeddedImage: null,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Número de cuenta
                  GestureDetector(
                    onTap: () => _copyAccountNumber(account.accountNumber),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppFormatters.accountNumber(account.accountNumber),
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy_rounded,
                              color: AppColors.primary, size: 16),
                        ],
                      ),
                    ),
                  ),

                  if (_fixedAmount != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Monto fijo: ${AppFormatters.currency(_fixedAmount!)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Monto fijo ──
            if (!_showAmountField && _fixedAmount == null)
              OutlinedButton.icon(
                onPressed: () => setState(() => _showAmountField = true),
                icon: const Icon(Icons.attach_money_rounded,
                    color: AppColors.primary),
                label: Text(
                  'Fijar monto de cobro',
                  style: GoogleFonts.poppins(
                      color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),

            if (_showAmountField && _fixedAmount == null)
              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SmartBankTextField(
                        label: 'Monto a cobrar',
                        controller: _amountController,
                        prefixIcon: Icons.attach_money_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: AppValidators.amount,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _applyAmount(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _clearAmount,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Cancelar',
                                  style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SmartBankButton(
                              label: 'Aplicar',
                              onPressed: _applyAmount,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            if (_fixedAmount != null) ...[
              OutlinedButton.icon(
                onPressed: _clearAmount,
                icon: const Icon(Icons.close_rounded, color: AppColors.error),
                label: Text(
                  'Quitar monto fijo',
                  style: GoogleFonts.poppins(
                      color: AppColors.error, fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
