import 'package:flutter/material.dart';

enum AppNotificationType { booking, order, payment, checkIn, system }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final AppNotificationType type;
  final DateTime createdAt;
  final String? refId; // booking id / order id, etc.
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.refId,
    this.read = false,
  });

  IconData get icon {
    switch (type) {
      case AppNotificationType.booking:
        return Icons.event_available;
      case AppNotificationType.order:
        return Icons.room_service;
      case AppNotificationType.payment:
        return Icons.payments;
      case AppNotificationType.checkIn:
        return Icons.login;
      case AppNotificationType.system:
        return Icons.info_outline;
    }
  }

  Color get color {
    switch (type) {
      case AppNotificationType.booking:
        return Colors.blue;
      case AppNotificationType.order:
        return Colors.orange;
      case AppNotificationType.payment:
        return Colors.green;
      case AppNotificationType.checkIn:
        return Colors.teal;
      case AppNotificationType.system:
        return Colors.grey;
    }
  }
}
