import 'package:hive/hive.dart';

part 'mute_settings_model.g.dart';

/// Mute duration options
enum MuteDuration {
  oneHour,
  twoHours,
  eightHours,
  oneDay,
  oneWeek,
  forever,
}

extension MuteDurationExtension on MuteDuration {
  String get label {
    switch (this) {
      case MuteDuration.oneHour:
        return 'ساعة واحدة';
      case MuteDuration.twoHours:
        return 'ساعتين';
      case MuteDuration.eightHours:
        return '8 ساعات';
      case MuteDuration.oneDay:
        return 'يوم كامل';
      case MuteDuration.oneWeek:
        return 'أسبوع';
      case MuteDuration.forever:
        return 'للأبد';
    }
  }

  String get labelEn {
    switch (this) {
      case MuteDuration.oneHour:
        return '1 hour';
      case MuteDuration.twoHours:
        return '2 hours';
      case MuteDuration.eightHours:
        return '8 hours';
      case MuteDuration.oneDay:
        return '1 day';
      case MuteDuration.oneWeek:
        return '1 week';
      case MuteDuration.forever:
        return 'Forever';
    }
  }

  Duration? get duration {
    switch (this) {
      case MuteDuration.oneHour:
        return const Duration(hours: 1);
      case MuteDuration.twoHours:
        return const Duration(hours: 2);
      case MuteDuration.eightHours:
        return const Duration(hours: 8);
      case MuteDuration.oneDay:
        return const Duration(days: 1);
      case MuteDuration.oneWeek:
        return const Duration(days: 7);
      case MuteDuration.forever:
        return null; // null means forever
    }
  }

  DateTime? getMutedUntil() {
    final dur = duration;
    if (dur == null) return null;
    return DateTime.now().add(dur);
  }
}

@HiveType(typeId: 10)
class MuteSettingsModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? odId; // user who muted

  @HiveField(2)
  String? targetId; // chat or group id

  @HiveField(3)
  String? targetType; // 'chat' or 'group'

  @HiveField(4)
  bool isMuted;

  @HiveField(5)
  DateTime? mutedUntil; // null = forever

  @HiveField(6)
  bool allowMentions;

  @HiveField(7)
  bool allowPinned;

  @HiveField(8)
  DateTime? createdAt;

  @HiveField(9)
  DateTime? updatedAt;

  MuteSettingsModel({
    this.id,
    this.odId,
    this.targetId,
    this.targetType,
    this.isMuted = false,
    this.mutedUntil,
    this.allowMentions = true,
    this.allowPinned = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if currently muted (considering expiration)
  bool get isCurrentlyMuted {
    if (!isMuted) return false;
    if (mutedUntil == null) return true; // forever
    return DateTime.now().isBefore(mutedUntil!);
  }

  /// Get remaining mute time as string
  String get remainingTimeText {
    if (!isCurrentlyMuted) return '';
    if (mutedUntil == null) return 'للأبد';

    final remaining = mutedUntil!.difference(DateTime.now());
    if (remaining.inDays > 0) {
      return '${remaining.inDays} يوم';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours} ساعة';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes} دقيقة';
    }
    return 'أقل من دقيقة';
  }

  factory MuteSettingsModel.fromJson(Map<String, dynamic> json) {
    return MuteSettingsModel(
      id: json['id'],
      odId: json['user_id'],
      targetId: json['target_id'],
      targetType: json['target_type'],
      isMuted: json['is_muted'] ?? false,
      mutedUntil: json['muted_until'] != null
          ? DateTime.parse(json['muted_until'])
          : null,
      allowMentions: json['allow_mentions'] ?? true,
      allowPinned: json['allow_pinned'] ?? true,
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
      'target_id': targetId,
      'target_type': targetType,
      'is_muted': isMuted,
      'muted_until': mutedUntil?.toIso8601String(),
      'allow_mentions': allowMentions,
      'allow_pinned': allowPinned,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  MuteSettingsModel copyWith({
    String? id,
    String? odId,
    String? targetId,
    String? targetType,
    bool? isMuted,
    DateTime? mutedUntil,
    bool? allowMentions,
    bool? allowPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearMutedUntil = false,
  }) {
    return MuteSettingsModel(
      id: id ?? this.id,
      odId: odId ?? this.odId,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      isMuted: isMuted ?? this.isMuted,
      mutedUntil: clearMutedUntil ? null : (mutedUntil ?? this.mutedUntil),
      allowMentions: allowMentions ?? this.allowMentions,
      allowPinned: allowPinned ?? this.allowPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
