import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_banco/core/constants/app.colors.dart';
import 'package:app_banco/core/utils/formatters.dart';
import 'package:app_banco/features/auth/providers/auth.provider.dart';
import 'package:app_banco/features/accounts/providers/account.provider.dart';
import 'package:app_banco/features/notifications/models/notification.model.dart';
import 'package:app_banco/features/notifications/providers/notification.provider.dart';
import 'package:app_banco/features/notifications/widgets/expenses_chart.widget.dart';

/// Pantalla que muestra el historial de notificaciones del usuario
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<NotificationProvider>().loadNotifications(
          auth.currentUser!.uid,
        );
      }
    });
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.transferReceived:
        return Icons.call_received_rounded;
      case NotificationType.securityAlert:
        return Icons.security_rounded;
      case NotificationType.systemPromo:
        return Icons.local_offer_rounded;
      case NotificationType.generalInfo:
        return Icons.info_outline_rounded;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.transferReceived:
        return AppColors.success;
      case NotificationType.securityAlert:
        return AppColors.error;
      case NotificationType.systemPromo:
        return AppColors.accent;
      case NotificationType.generalInfo:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final auth = context.watch<AuthProvider>();
    final accountProv = context.watch<AccountProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Alertas y Gastos',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () {
                if (auth.currentUser != null) {
                  provider.markAllAsRead(auth.currentUser!.uid);
                }
              },
              child: Text(
                'Marcar leídas',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: provider.isLoading || accountProv.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                if (auth.currentUser != null) {
                  await Future.wait([
                    provider.loadNotifications(auth.currentUser!.uid),
                    accountProv.refreshTransactions(auth.currentUser!.uid),
                  ]);
                }
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Gráfico de Gastos ──
                  ExpensesChartWidget(
                    transactions: accountProv.recentTransactions,
                  ),
                  const SizedBox(height: 32),

                  // ── Título de Notificaciones ──
                  Text(
                    'Historial de Alertas',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Lista de Notificaciones ──
                  if (provider.notifications.isEmpty)
                    _EmptyNotifications()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.notifications.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notif = provider.notifications[index];
                        return _NotificationTile(
                          notification: notif,
                          icon: _getIconForType(notif.type),
                          color: _getColorForType(notif.type),
                          onTap: () {
                            if (!notif.isRead) {
                              provider.markAsRead(notif.id);
                            }
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? Colors.transparent : color.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppFormatters.relativeDate(notification.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_rounded,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No tienes notificaciones',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aquí aparecerán tus alertas y\ntransferencias recibidas.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
