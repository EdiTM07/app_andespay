import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_banco/core/constants/app.colors.dart';
import 'package:app_banco/core/utils/formatters.dart';
import 'package:app_banco/core/widgets/smartbank_button.dart';
import 'package:app_banco/features/transfers/providers/transfer.provider.dart';

/// Pantalla de comprobante de transferencia exitosa
class TransferSuccessPage extends StatefulWidget {
  const TransferSuccessPage({super.key});

  @override
  State<TransferSuccessPage> createState() => _TransferSuccessPageState();
}

class _TransferSuccessPageState extends State<TransferSuccessPage>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _confettiController;
  late Animation<double> _checkScale;
  late Animation<double> _checkFade;

  final List<_ConfettiPiece> _confetti = List.generate(
    18,
    (i) => _ConfettiPiece(
      color: [
        AppColors.primary,
        AppColors.success,
        const Color(0xFF80CBC4),
        const Color(0xFFA5D6A7),
        Colors.white,
      ][i % 5],
      left: Random().nextDouble(),
      speed: 0.4 + Random().nextDouble() * 0.6,
      size: 6 + Random().nextDouble() * 8,
    ),
  );

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    _checkFade = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOut,
    );

    _checkController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _confettiController.forward();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transfer = context.watch<TransferProvider>();
    final tx = transfer.lastTransaction;
    final recipientName = transfer.recipientUser?.fullName ?? 'Destinatario';
    final recipientAccount = transfer.recipientAccount?.accountNumber ?? '';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          // ── Confeti animado ──
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ConfettiPainter(
                  pieces: _confetti,
                  progress: _confettiController.value,
                ),
              );
            },
          ),

          // ── Contenido ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),

                            // Check animado
                            FadeTransition(
                              opacity: _checkFade,
                              child: ScaleTransition(
                                scale: _checkScale,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 52,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            Text(
                              '¡Transferencia exitosa!',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tu dinero fue enviado correctamente',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // ── Comprobante ──
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.07,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _ReceiptRow(
                                    label: 'Monto enviado',
                                    value: tx != null
                                        ? AppFormatters.currency(tx.amount)
                                        : '--',
                                    bold: true,
                                    valueColor: AppColors.primary,
                                  ),
                                  const Divider(
                                    height: 20,
                                    color: Color(0xFFF0F0F0),
                                  ),
                                  _ReceiptRow(
                                    label: 'Para',
                                    value: recipientName,
                                  ),
                                  const SizedBox(height: 10),
                                  _ReceiptRow(
                                    label: 'Cuenta destino',
                                    value: AppFormatters.accountNumber(
                                      recipientAccount,
                                    ),
                                  ),
                                  if (tx?.concept != null) ...[
                                    const SizedBox(height: 10),
                                    _ReceiptRow(
                                      label: 'Concepto',
                                      value: tx!.concept!,
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  _ReceiptRow(
                                    label: 'Fecha',
                                    value: tx != null
                                        ? AppFormatters.dateTime(tx.createdAt)
                                        : '--',
                                  ),
                                  const SizedBox(height: 10),
                                  _ReceiptRow(
                                    label: 'Referencia',
                                    value:
                                        tx?.id.substring(0, 8).toUpperCase() ??
                                        '--',
                                  ),
                                  const Divider(
                                    height: 20,
                                    color: Color(0xFFF0F0F0),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: AppColors.success,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Completada',
                                              style: GoogleFonts.poppins(
                                                color: AppColors.success,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // ── Acciones ──
                            SmartBankButton(
                              label: 'Ir al inicio',
                              onPressed: () {
                                transfer.reset();
                                context.go('/dashboard');
                              },
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                transfer.reset();
                                context.go('/transfer');
                              },
                              child: Text(
                                'Hacer otra transferencia',
                                style: GoogleFonts.poppins(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Confeti ──
class _ConfettiPiece {
  final Color color;
  final double left;
  final double speed;
  final double size;
  const _ConfettiPiece({
    required this.color,
    required this.left,
    required this.speed,
    required this.size,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  const _ConfettiPainter({required this.pieces, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final piece in pieces) {
      final y = -30 + (size.height + 60) * progress * piece.speed;
      final x =
          piece.left * size.width +
          sin(progress * 2 * pi + piece.left * 10) * 30;

      if (y > size.height) continue;

      paint.color = piece.color.withValues(alpha: 1 - progress * 0.5);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 2 * pi * piece.speed);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size * 0.5,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
