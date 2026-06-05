import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de notificaciones que puede recibir el usuario
enum NotificationType {
  transferReceived,
  securityAlert,
  systemPromo,
  generalInfo,
}

/// Modelo de notificación para AndesPay
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType parsedType;
    switch (json['type'] as String?) {
      case 'transfer_received':
        parsedType = NotificationType.transferReceived;
        break;
      case 'security_alert':
        parsedType = NotificationType.securityAlert;
        break;
      case 'system_promo':
        parsedType = NotificationType.systemPromo;
        break;
      default:
        parsedType = NotificationType.generalInfo;
    }

    DateTime parsedDate;
    if (json['createdAt'] is Timestamp) {
      parsedDate = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      parsedDate = DateTime.parse(json['createdAt'] as String);
    } else {
      parsedDate = DateTime.now();
    }

    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: parsedType,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: parsedDate,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    String typeString;
    switch (type) {
      case NotificationType.transferReceived:
        typeString = 'transfer_received';
        break;
      case NotificationType.securityAlert:
        typeString = 'security_alert';
        break;
      case NotificationType.systemPromo:
        typeString = 'system_promo';
        break;
      case NotificationType.generalInfo:
        typeString = 'general_info';
        break;
    }

    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': typeString,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      if (data != null) 'data': data,
    };
  }
}
