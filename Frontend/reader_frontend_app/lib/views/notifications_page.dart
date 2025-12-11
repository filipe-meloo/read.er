import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<NotificationModel>> futureNotifications;

  @override
  void initState() {
    super.initState();
    futureNotifications = NotificationService().fetchNotifications();
  }

  IconData _getIconForNotificationType(String type) {
    // Associa tipos de notificações a ícones
    switch (type) {
      case 'friend_request':
        return Icons.person_add;
      case 'message':
        return Icons.message;
      case 'post_reaction':
        return Icons.thumb_up;
      case 'comment':
        return Icons.comment;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.notifications; // Ícone genérico
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1B3A),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          backgroundColor: const Color(0xFF2C1B3A),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Text(
                'Notificações',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: futureNotifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Erro ao carregar notificações.',
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma notificação.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final notification = snapshot.data![index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF241731),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Icon(
                        _getIconForNotificationType(notification.type),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      notification.content,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Text(
                      _formatDate(notification.dateCreated),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Formata a data para exibir em um estilo amigável
    return "${date.day}/${date.month}/${date.year}";
  }
}
