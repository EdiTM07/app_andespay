import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:app_banco/core/constants/app.colors.dart';
import 'package:app_banco/features/auth/providers/auth.provider.dart';
import 'package:app_banco/features/accounts/providers/account.provider.dart';
import 'package:app_banco/core/utils/formatters.dart';

/// Pantalla de perfil del usuario autenticado
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final accountProv = context.watch<AccountProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Mi Perfil',
            style: GoogleFonts.poppins(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar ──
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              backgroundImage:
                  user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
              child: user?.photoUrl == null
                  ? Text(
                      (user?.fullName ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 36,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user?.fullName ?? '',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppColors.textSecondary),
            ),

            const SizedBox(height: 28),

            // ── Info de cuenta ──
            if (accountProv.account != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Número de cuenta',
                      value: AppFormatters.accountNumber(
                          accountProv.account!.accountNumber),
                    ),
                    const Divider(height: 24, color: Color(0xFFF0F0F0)),
                    _InfoRow(
                      label: 'Tipo de cuenta',
                      value: accountProv.account!.accountType,
                    ),
                    const Divider(height: 24, color: Color(0xFFF0F0F0)),
                    _InfoRow(
                      label: 'Saldo',
                      value: AppFormatters.currency(accountProv.account!.balance),
                      valueColor: AppColors.primary,
                      bold: true,
                    ),
                    const Divider(height: 24, color: Color(0xFFF0F0F0)),
                    _InfoRow(
                      label: 'Miembro desde',
                      value: AppFormatters.date(user?.createdAt ?? DateTime.now()),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // ── Acciones ──
            _ProfileAction(
              icon: Icons.edit_outlined,
              label: 'Editar perfil',
              onTap: () => context.push('/edit-profile'),
            ),
            const SizedBox(height: 8),
            _ProfileAction(
              icon: Icons.lock_outline,
              label: 'Cambiar PIN',
              onTap: () => context.push('/pin-setup'),
            ),
            const SizedBox(height: 8),
            _ProfileAction(
              icon: Icons.logout_rounded,
              label: 'Cerrar sesión',
              color: AppColors.error,
              onTap: () async {
                context.read<AccountProvider>().clear();
                await auth.signOut();
                if (context.mounted) context.go('/login');
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            )),
      ],
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w500, color: c)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: c.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}
