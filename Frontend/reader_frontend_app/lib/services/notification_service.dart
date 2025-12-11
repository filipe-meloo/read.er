import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:reader_frontend_app/services/config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/status.dart' as status;
import '../models/notification_model.dart';
import 'auth_provider.dart';
import 'auth_service.dart';

class NotificationService {
  WebSocketChannel? _channel;

  // Método para buscar notificações iniciais via HTTP
  Future<List<NotificationModel>> fetchNotifications() async {
    final userId = await AuthProvider().getCurrentUserId();
    final url = Uri.parse('$BASE_URL/api/Notification/user/$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  // Método para iniciar websocket connection
  Future<void> connectWebSocket () async {
    bool isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      String? token = await AuthProvider().getToken();
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://10.2.2.2:8000/ws/notifications?token=$token'),
      );
      _listenToMessages();
    }
  }

  void _listenToMessages() {
    _channel!.stream.listen(
          (message) {
        _showNotification(message);
      },
      onError: (error) {
        print("Erro no WebSocket: $error");
      },
      onDone: () {
        print("Conexão WebSocket encerrada");
      },
    );
  }

  void _showNotification(String message) {
    final notification = json.decode(message);
    showSimpleNotification(
      Text(notification['Title']),
      subtitle: Text(notification['Content']),
      background: Colors.purpleAccent,
      duration: Duration(seconds: 2),
    );
  }

  void disconnectWebSocket() {
    _channel?.sink.close(status.normalClosure);
  }

}
