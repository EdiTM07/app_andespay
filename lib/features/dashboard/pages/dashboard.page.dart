import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_banco/core/constants/app.colors.dart';
import 'package:app_banco/features/accounts/providers/account.provider.dart';
import 'package:app_banco/features/auth/providers/auth.provider.dart';
import 'package:app_banco/features/dashboard/widgets/balance_card.widget.dart';
import 'package:app_banco/features/dashboard/widgets/quick_actions.widget.dart';
import 'package:app_banco/features/dashboard/widgets/recent_transactions.widget.dart';

/// Pantalla principal del usuario autenticado en AndesPay
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  void _loadAccountData() {
    final auth = context.read<AuthProvider>();
    if (auth.currentUser == null) return;

    context.read<AccountProvider>().loadAccount(auth.currentUser!.uid);
  }

  Future<void> _onRefresh() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    await context.read<AccountProvider>().refreshTransactions(uid);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final accountProv = context.watch<AccountProvider>();

    final firstName = auth.currentUser?.fullName.split(' ').first ?? 'Usuario';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── AppBar personalizado ──
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              snap: true,
              backgroundColor: AppColors.scaffoldBackground,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, $firstName 👋',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Bienvenido a AndesPay',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Avatar / Notificaciones
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.push('/notifications'),
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          backgroundImage:
                              auth.currentUser?.photoUrl != null
                                  ? NetworkImage(auth.currentUser!.photoUrl!)
                                  : null,
                          child: auth.currentUser?.photoUrl == null
                              ? Text(
                                  firstName[0].toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Tarjeta de saldo ──
                    _buildBalanceSection(accountProv, auth),

                    const SizedBox(height: 28),

                    // ── Acciones rápidas ──
                    const QuickActionsWidget(),

                    const SizedBox(height: 28),

                    // ── Transacciones recientes ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: RecentTransactionsWidget(
                        transactions: accountProv.recentTransactions,
                        onSeeAll: () => context.push('/account-detail'),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSection(AccountProvider accountProv, AuthProvider auth) {
    if (accountProv.isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (accountProv.account == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              'Cargando tu cuenta...',
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return BalanceCardWidget(
      account: accountProv.account!,
      ownerName: auth.currentUser?.fullName ?? '',
    );
  }
}
