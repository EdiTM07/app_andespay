import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_banco/core/constants/app.colors.dart';
import 'package:app_banco/core/utils/security_helpers.dart';
import 'package:app_banco/features/auth/providers/auth.provider.dart';
import 'package:app_banco/features/auth/repositories/auth.repository.dart';

/// Pantalla de configuración del PIN de seguridad (4 dígitos)
/// Se presenta después del registro exitoso
class PinSetupPage extends StatefulWidget {
  const PinSetupPage({super.key});

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  static const int _pinLength = 4;

  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isLoading = false;
  String? _errorText;

  // Agrega un dígito al PIN actual
  void _onKeyTap(String digit) {
    setState(() {
      _errorText = null;
      if (!_isConfirming && _pin.length < _pinLength) {
        _pin += digit;
        if (_pin.length == _pinLength) _isConfirming = true;
      } else if (_isConfirming && _confirmPin.length < _pinLength) {
        _confirmPin += digit;
        if (_confirmPin.length == _pinLength) _onPinComplete();
      }
    });
  }

  // Elimina el último dígito
  void _onDelete() {
    setState(() {
      _errorText = null;
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _isConfirming = false;
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  // Reinicia el proceso de entrada de PIN
  void _resetPin() {
    setState(() {
      _pin = '';
      _confirmPin = '';
      _isConfirming = false;
      _errorText = null;
    });
  }

  // Verifica los PINs y guarda en Firestore
  Future<void> _onPinComplete() async {
    if (_pin != _confirmPin) {
      setState(() {
        _errorText = 'Los PINs no coinciden. Inténtalo de nuevo.';
        _confirmPin = '';
        // Pequeño delay para mostrar el error antes de resetear
      });
      await Future.delayed(const Duration(milliseconds: 800));
      _resetPin();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final uid = auth.currentUser?.uid;
      if (uid == null) throw Exception('Usuario no autenticado.');

      final pinHash = SecurityHelpers.hashPin(_pin);
      await AuthRepository().updatePinHash(uid: uid, pinHash: pinHash);

      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = 'No se pudo guardar el PIN. Intenta de nuevo.';
        });
        _resetPin();
      }
    }
  }

  // Omitir configuración del PIN (puede hacerlo después)
  void _onSkip() => context.go('/dashboard');

  // ── UI ──

  String get _currentPin => _isConfirming ? _confirmPin : _pin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Fondo decorativo
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
              ),
            ),

            Column(
              children: [
                const SizedBox(height: 32),

                // ── Título y subtítulo ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isConfirming ? 'Confirma tu PIN' : 'Crea tu PIN',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isConfirming
                            ? 'Ingresa de nuevo el PIN para confirmarlo'
                            : 'Este PIN protegerá tus transacciones',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ── Indicadores de puntos del PIN ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (i) {
                    final filled = i < _currentPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: filled ? 18 : 16,
                      height: filled ? 18 : 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppColors.primary.withValues(
                              alpha: filled ? 1.0 : 0.3),
                          width: 1.5,
                        ),
                        boxShadow: filled
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                )
                              ]
                            : [],
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                // ── Mensaje de error ──
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _errorText != null ? 1.0 : 0.0,
                  child: Text(
                    _errorText ?? '',
                    style: GoogleFonts.poppins(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const Spacer(),

                // ── Teclado numérico personalizado ──
                if (_isLoading)
                  const CircularProgressIndicator(color: AppColors.primary)
                else
                  _PinKeypad(
                    onKeyTap: _onKeyTap,
                    onDelete: _onDelete,
                  ),

                const SizedBox(height: 28),

                // ── Omitir ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: TextButton(
                    onPressed: _onSkip,
                    child: Text(
                      'Configurar más tarde',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Teclado numérico personalizado para el PIN
class _PinKeypad extends StatelessWidget {
  final void Function(String) onKeyTap;
  final VoidCallback onDelete;

  const _PinKeypad({required this.onKeyTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          ...keys.map(
            (row) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row
                  .map((digit) => _KeypadButton(
                        digit: digit,
                        onTap: () => onKeyTap(digit),
                      ))
                  .toList(),
            ),
          ),
          // Fila final: vacío | 0 | borrar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72, height: 72), // espacio vacío
              _KeypadButton(digit: '0', onTap: () => onKeyTap('0')),
              _DeleteButton(onTap: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;

  const _KeypadButton({required this.digit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DeleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            color: AppColors.error,
            size: 24,
          ),
        ),
      ),
    );
  }
}