import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_banco/core/constants/app.colors.dart';
import 'package:app_banco/core/utils/formatters.dart';
import 'package:app_banco/features/accounts/providers/account.provider.dart';
import 'package:app_banco/features/auth/providers/auth.provider.dart';
import 'package:app_banco/features/transfers/models/transaction.model.dart';

/// Detalle de cuenta de ahorros con historial completo de movimientos
class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({super.key});

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  TransactionType? _filter; // null = todos

  List<TransactionModel> _filtered(List<TransactionModel> all) {
    if (_filter == null) return all;
    return all.where((t) => t.type == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final accountProv = context.watch<AccountProvider>();
    final auth = context.watch<AuthProvider>();
    final transactions = _filtered(accountProv.recentTransactions);

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
          'Mi Cuenta',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () {
              final uid = auth.currentUser?.uid;
              if (uid != null) accountProv.refreshTransactions(uid);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Resumen de cuenta ──
          if (accountProv.account != null)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              padding: const EdgeInsets.all(20),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cuenta de Ahorros',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppFormatters.currency(accountProv.account!.balance),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppFormatters.accountNumber(
                            accountProv.account!.accountNumber),
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ],
              ),
            ),

          // ── Filtros ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todos',
                  isSelected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Recibidos',
                  isSelected: _filter == TransactionType.credit,
                  onTap: () => setState(() => _filter = TransactionType.credit),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Enviados',
                  isSelected: _filter == TransactionType.debit,
                  onTap: () => setState(() => _filter = TransactionType.debit),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Lista ──
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 56,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'Sin movimientos',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: transactions.length,
                    separatorBuilder: (context, _) => const Divider(
                        height: 1, indent: 56, color: Color(0xFFF0F0F0)),
                    itemBuilder: (context, i) {
                      final tx = transactions[i];
                      final isCredit = tx.isCredit;
                      final amountColor =
                          isCredit ? AppColors.success : AppColors.error;

                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 6),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: amountColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isCredit
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: amountColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          tx.concept ??
                              (isCredit
                                  ? 'Transferencia recibida'
                                  : 'Transferencia enviada'),
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          AppFormatters.dateTime(tx.createdAt),
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: Text(
                          '${isCredit ? '+' : '-'}${AppFormatters.currency(tx.amount)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: amountColor,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
