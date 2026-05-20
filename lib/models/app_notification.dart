class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final String createdAt;
  final String? code;
  final String? iconKey;
  final int? accentColor;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.code,
    this.iconKey,
    this.accentColor,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final accentRaw = json['accentColor'];
    int? accentColor;
    if (accentRaw is int) {
      accentColor = accentRaw;
    } else if (accentRaw is String) {
      accentColor = int.tryParse(accentRaw);
    }

    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      createdAt: json['createdAt'] as String,
      code: json['code'] as String?,
      iconKey: json['iconKey'] as String?,
      accentColor: accentColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'createdAt': createdAt,
      'code': code,
      'iconKey': iconKey,
      'accentColor': accentColor,
    };
  }
}
