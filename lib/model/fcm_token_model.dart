class FCMTokenModel {
  String? id;
  String? odId;
  String? token;
  String? deviceName;
  String? platform; // 'android', 'ios', 'web'
  bool isActive;
  DateTime? createdAt;
  DateTime? updatedAt;

  FCMTokenModel({
    this.id,
    this.odId,
    this.token,
    this.deviceName,
    this.platform,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory FCMTokenModel.fromJson(Map<String, dynamic> json) {
    return FCMTokenModel(
      id: json['id'],
      odId: json['user_id'],
      token: json['token'],
      deviceName: json['device_name'],
      platform: json['platform'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': odId,
      'token': token,
      'device_name': deviceName,
      'platform': platform,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
