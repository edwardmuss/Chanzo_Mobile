class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? link;
  final DateTime createdAt;
  final String icon;
  final String sound;
  final String priority;
  final bool unread;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.link,
    required this.createdAt,
    required this.icon,
    required this.sound,
    required this.priority,
    required this.unread,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      body: json['body'],
      link: json['link'],
      createdAt: DateTime.parse(json['created_at']),
      icon: json['icon'] ?? 'bx bx-bell',
      sound: json['sound'] ?? 'default',
      priority: json['priority'] ?? 'normal',
      unread: json['unread'] ?? false,
    );
  }
}

extension NotificationModelCopyWith on NotificationModel {
  NotificationModel copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
    String? link,
    DateTime? createdAt,
    String? icon,
    String? sound,
    String? priority,
    bool? unread,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      link: link ?? this.link,
      createdAt: createdAt ?? this.createdAt,
      icon: icon ?? this.icon,
      sound: sound ?? this.sound,
      priority: priority ?? this.priority,
      unread: unread ?? this.unread,
    );
  }
}