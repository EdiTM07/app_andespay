import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_banco/core/constants/app.colors.dart';
import 'package:app_banco/core/utils/formatters.dart';
import 'package:app_banco/features/accounts/models/account.model.dart';

/// Tarjeta de saldo principal — diseño tipo tarjeta bancaria
class BalanceCardWidget extends StatefulWidget {
  final AccountModel account;
  final String ownerName;

  const BalanceCardWidget({
    super.key,
    required this.account,
    required this.ownerName,
  });

  @override
  State<BalanceCardWidget> createState() => _BalanceCardWidgetState();
}

class _BalanceCardWidgetState extends State<BalanceCardWidget>
    with SingleTickerProviderStateMixin {
  bool _balanceVisible = true;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _copyAccountNumber() {
    Clipboard.setData(ClipboardData(text: widget.account.accountNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Número copiado',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFF00695C),
                Color(0xFF00897B),
                Color(0xFF26A69A),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ── Efecto shimmer decorativo ──
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CustomPaint(
                    painter: _CardPatternPainter(_shimmerAnimation.value),
                  ),
                ),
              ),

              // ── Contenido ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila superior: tipo de cuenta + ícono
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.account.accountType,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              widget.ownerName,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Saldo
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _balanceVisible = !_balanceVisible),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saldo disponible',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedCrossFade(
                                  duration: const Duration(milliseconds: 300),
                                  crossFadeState: _balanceVisible
                                      ? CrossFadeState.showFirst
                                      : CrossFadeState.showSecond,
                                  firstChild: Text(
                                    AppFormatters.currency(
                                        widget.account.balance),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  secondChild: Text(
                                    '\$ ••••••',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Botón ocultar saldo
                        IconButton(
                          onPressed: () =>
                              setState(() => _balanceVisible = !_balanceVisible),
                          icon: Icon(
                            _balanceVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 20,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Número de cuenta
                    GestureDetector(
                      onTap: _copyAccountNumber,
                      child: Row(
                        children: [
                          Text(
                            AppFormatters.accountNumber(
                                widget.account.accountNumber),
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 14,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.copy_rounded,
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Painter para el patrón decorativo de la tarjeta
class _CardPatternPainter extends CustomPainter {
  final double shimmerOffset;
  _CardPatternPainter(this.shimmerOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    // Círculos decorativos
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.1), 90, paint);
    canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 0.9), 60, paint);

    // Línea shimmer
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(
        shimmerOffset * size.width,
        0,
        size.width * 0.4,
        size.height,
      ));
    canvas.drawRect(
      Rect.fromLTWH(shimmerOffset * size.width, 0, size.width * 0.4,
          size.height),
      shimmerPaint,
    );
  }

  @override
  bool shouldRepaint(_CardPatternPainter old) => old.shimmerOffset != shimmerOffset;
}
