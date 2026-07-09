class AppNotification {
  final int? id;
  final String? title;
  final String? description;
  final String? type;
  final bool? isRead;
  final DateTime? createdAt;

  const AppNotification({
    this.id,
    this.title,
    this.description,
    this.type,
    this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final raw = json['createdAt'] ?? json['created_at'] ?? json['timestamp'];
    if (raw is String) {
      created = DateTime.tryParse(raw);
    } else if (raw is int) {
      created = DateTime.fromMillisecondsSinceEpoch(raw);
    }

    int? parsedId;
    final rid = json['id'] ?? json['notificationId'];
    if (rid is int) parsedId = rid;
    if (rid is String) parsedId = int.tryParse(rid);

    final isReadRaw = json['is_read'] ?? json['isRead'];
    bool? isRead;
    if (isReadRaw is bool) isRead = isReadRaw;
    if (isReadRaw is int) isRead = isReadRaw == 1;
    if (isReadRaw is String) {
      isRead = isReadRaw.toLowerCase() == 'true' || isReadRaw == '1';
    }

    return AppNotification(
      id: parsedId,
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      type: json['type']?.toString(),
      isRead: isRead,
      createdAt: created,
    );
  }
}

