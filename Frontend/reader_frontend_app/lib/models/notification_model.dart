
class NotificationModel {
  final int userId;
  final String title;
  final String content;
  final String type;
  final DateTime dateCreated;
  final bool read;

  NotificationModel({
    required this.userId,
    required this.title,
    required this.content,
    required this.type,
    required this.dateCreated,
    required this.read,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      userId: json['userId'],
      title: json['title'],
      content: json['content'],
      type: json['type'],
      dateCreated: DateTime.parse(json['dateCreated']),
      read: json['read'],
    );
  }
}