import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_banco/core/constants/app.firestore_collections.dart';
import 'package:app_banco/features/notifications/models/notification.model.dart';
import 'package:app_banco/services/firestore_service.dart';

/// Provider para la gestión de notificaciones
class NotificationProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Cargar notificaciones del usuario de forma reactiva (en tiempo real si lo quisiéramos,
  /// pero aquí haremos un fetch manual para simplificar)
  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final docs = await FirebaseFirestore.instance
          .collection(AppCollections.notifications)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _notifications = docs.docs
          .map((d) => NotificationModel.fromJson(d.data()))
          .toList();
    } catch (e) {
      _errorMessage = 'No se pudieron cargar las notificaciones.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marcar una notificación como leída
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db.updateDocument(
        collection: AppCollections.notifications,
        docId: notificationId,
        data: {'isRead': true},
      );

      // Actualizar el estado local
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final notif = _notifications[index];
        _notifications[index] = NotificationModel(
          id: notif.id,
          userId: notif.userId,
          title: notif.title,
          body: notif.body,
          type: notif.type,
          isRead: true,
          createdAt: notif.createdAt,
          data: notif.data,
        );
        notifyListeners();
      }
    } catch (e) {
      // Ignorar el error de manera silenciosa para la UI
    }
  }

  /// Marcar todas las notificaciones como leídas
  Future<void> markAllAsRead(String userId) async {
    try {
      final unread = _notifications.where((n) => !n.isRead).toList();
      if (unread.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (final n in unread) {
        final ref = FirebaseFirestore.instance
            .collection(AppCollections.notifications)
            .doc(n.id);
        batch.update(ref, {'isRead': true});
      }
      await batch.commit();

      // Actualizar el estado local
      _notifications = _notifications.map((n) {
        if (!n.isRead) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            title: n.title,
            body: n.body,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
            data: n.data,
          );
        }
        return n;
      }).toList();
      notifyListeners();
    } catch (e) {
      // Ignorar el error silenciosamente
    }
  }

  /// Limpiar estado (al hacer logout)
  void clear() {
    _notifications = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
