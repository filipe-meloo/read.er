import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void startListeningForNotifications() {
    _notificationService.connectWebSocket();
  }

  void stopListeningForNotifications() {
    _notificationService.disconnectWebSocket();
  }
}
