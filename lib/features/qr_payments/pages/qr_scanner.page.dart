import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app_banco/core/constants/app.colors.dart';
import 'package:app_banco/features/accounts/providers/account.provider.dart';
import 'package:app_banco/features/qr_payments/models/qr_data.model.dart';
import 'package:app_banco/features/transfers/providers/transfer.provider.dart';

/// Pantalla de escaneo QR para recibir datos del destinatario
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    await _controller.stop();

    // Decodificar el QR
    final qrData = QrDataModel.decode(raw);

    if (!mounted) return;

    if (qrData == null) {
      setState(() {
        _errorMessage = 'Este QR no es compatible con AndesPay.';
        _isProcessing = false;
      });
      _controller.start();
      return;
    }

    // Verificar que no sea el propio QR del usuario
    final myAccount = context.read<AccountProvider>().account;
    if (myAccount?.accountNumber == qrData.accountNumber) {
      setState(() {
        _errorMessage = 'No puedes transferirte a tu propia cuenta.';
        _isProcessing = false;
      });
      _controller.start();
      return;
    }

    // Buscar el destinatario en Firestore con el número del QR
    final transferProv = context.read<TransferProvider>();
    await transferProv.searchRecipient(qrData.accountNumber);

    if (!mounted) return;

    if (transferProv.status == TransferStatus.recipientFound) {
      // Navegar al flujo de confirmación con datos del QR
      context.push('/qr-payment-confirm', extra: {
        'amount': qrData.hasFixedAmount ? qrData.amount! : 0.0,
        'hasFixedAmount': qrData.hasFixedAmount,
        'concept': 'Pago QR AndesPay',
      });
    } else {
      setState(() {
        _errorMessage = 'No se encontró la cuenta del destinatario.';
        _isProcessing = false;
      });
      _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Cámara ──
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // ── Overlay oscuro con ventana QR ──
          _ScannerOverlay(),

          // ── UI superior ──
          SafeArea(
            child: Column(
              children: [
                // AppBar manual
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Escanear QR',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      // Linterna
                      ValueListenableBuilder(
                        valueListenable: _controller,
                        builder: (context, state, child) {
                          return IconButton(
                            icon: Icon(
                              state.torchState == TorchState.on
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: state.torchState == TorchState.on
                                  ? AppColors.primary
                                  : Colors.white,
                            ),
                            onPressed: _controller.toggleTorch,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Texto indicador
                Text(
                  'Apunta al código QR de AndesPay',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // ── Esquinas de la ventana de escaneo ──
          const Center(child: _ScanCorners()),

          // ── Mensaje de error ──
          if (_errorMessage != null)
            Positioned(
              bottom: 120,
              left: 24,
              right: 24,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _errorMessage != null ? 1 : 0,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Procesando ──
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),

          // ── Botón: mostrar mi QR ──
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: _MyQrButton(
              onTap: () => context.push('/qr-generator'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overlay oscuro con ventana transparente cuadrada ──
class _ScannerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const cutSize = 260.0;
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final left = (w - cutSize) / 2;
      final top = (h - cutSize) / 2 - 40;

      return Stack(
        children: [
          // Oscurecer todo
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                  Colors.transparent, BlendMode.multiply),
              child: CustomPaint(
                painter: _OverlayPainter(
                  cutRect: Rect.fromLTWH(left, top, cutSize, cutSize),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect cutRect;
  const _OverlayPainter({required this.cutRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(cutRect, const Radius.circular(16)));
    final combined = Path.combine(PathOperation.difference, fullPath, cutPath);
    canvas.drawPath(combined, paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.cutRect != cutRect;
}

// ── Esquinas decorativas del frame de escaneo ──
class _ScanCorners extends StatefulWidget {
  const _ScanCorners();

  @override
  State<_ScanCorners> createState() => _ScanCornersState();
}

class _ScanCornersState extends State<_ScanCorners>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scan;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _scan = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 260.0;
    const cornerLen = 28.0;
    const cornerThick = 3.5;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Línea de escaneo animada
          AnimatedBuilder(
            animation: _scan,
            builder: (context, child) {
              return Positioned(
                top: _scan.value * (size - 4),
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.primary.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Esquinas
          ...[
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ].map((alignment) {
            final isLeft = alignment == Alignment.topLeft ||
                alignment == Alignment.bottomLeft;
            final isTop = alignment == Alignment.topLeft ||
                alignment == Alignment.topRight;
            return Align(
              alignment: alignment,
              child: SizedBox(
                width: cornerLen,
                height: cornerLen,
                child: CustomPaint(
                  painter: _CornerPainter(
                    isLeft: isLeft,
                    isTop: isTop,
                    color: AppColors.primary,
                    thickness: cornerThick,
                    length: cornerLen,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isLeft;
  final bool isTop;
  final Color color;
  final double thickness;
  final double length;

  const _CornerPainter({
    required this.isLeft,
    required this.isTop,
    required this.color,
    required this.thickness,
    required this.length,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final x = isLeft ? 0.0 : size.width;
    final y = isTop ? 0.0 : size.height;
    final xDir = isLeft ? 1.0 : -1.0;
    final yDir = isTop ? 1.0 : -1.0;

    canvas.drawLine(Offset(x, y), Offset(x + xDir * length, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + yDir * length), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

// Botón flotante para mostrar el QR propio
class _MyQrButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MyQrButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_rounded,
                color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Text(
              'Mostrar mi código QR',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
