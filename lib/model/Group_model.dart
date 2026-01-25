import 'dart:convert';
import 'package:wissal_app/model/user_model.dart';

enum MemberRole {
  owner,
  admin,
  member,
}

class GroupMember {
  final String odId;
  final String name;
  final String? profileImage;
  final MemberRole role;
  final DateTime joinedAt;
  final bool isMuted;
  final DateTime? mutedUntil;

  GroupMember({
    required this.odId,
    required this.name,
    this.profileImage,
    this.role = MemberRole.member,
    DateTime? joinedAt,
    this.isMuted = false,
    this.mutedUntil,
  }) : joinedAt = joinedAt ?? DateTime.now();

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      odId: json['userId'] ?? '',
      name: json['name'] ?? '',
      profileImage: json['profileImage'],
      role: _parseRole(json['role']),
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
      isMuted: json['isMuted'] ?? false,
      mutedUntil: json['mutedUntil'] != null
          ? DateTime.parse(json['mutedUntil'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': odId,
        'name': name,
        'profileImage': profileImage,
        'role': role.name,
        'joinedAt': joinedAt.toIso8601String(),
        'isMuted': isMuted,
        'mutedUntil': mutedUntil?.toIso8601String(),
      };

  static MemberRole _parseRole(dynamic role) {
    if (role == null) return MemberRole.member;
    if (role is String) {
      switch (role.toLowerCase()) {
        case 'owner':
          return MemberRole.owner;
        case 'admin':
          return MemberRole.admin;
        default:
          return MemberRole.member;
      }
    }
    return MemberRole.member;
  }

  bool get isAdmin => role == MemberRole.admin || role == MemberRole.owner;
  bool get isOwner => role == MemberRole.owner;

  GroupMember copyWith({
    String? odId,
    String? name,
    String? profileImage,
    MemberRole? role,
    DateTime? joinedAt,
    bool? isMuted,
    DateTime? mutedUntil,
    bool clearMutedUntil = false,
  }) {
    return GroupMember(
      odId: odId ?? this.odId,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isMuted: isMuted ?? this.isMuted,
      mutedUntil: clearMutedUntil ? null : (mutedUntil ?? this.mutedUntil),
    );
  }
}

class GroupSettings {
  final bool isLocked;
  final bool onlyAdminsCanEditInfo;
  final bool onlyAdminsCanAddMembers;
  final int? maxMembers;

  const GroupSettings({
    this.isLocked = false,
    this.onlyAdminsCanEditInfo = true,
    this.onlyAdminsCanAddMembers = false,
    this.maxMembers,
  });

  factory GroupSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GroupSettings();
    return GroupSettings(
      isLocked: json['isLocked'] ?? false,
      onlyAdminsCanEditInfo: json['onlyAdminsCanEditInfo'] ?? true,
      onlyAdminsCanAddMembers: json['onlyAdminsCanAddMembers'] ?? false,
      maxMembers: json['maxMembers'],
    );
  }

  Map<String, dynamic> toJson() => {
        'isLocked': isLocked,
        'onlyAdminsCanEditInfo': onlyAdminsCanEditInfo,
        'onlyAdminsCanAddMembers': onlyAdminsCanAddMembers,
        'maxMembers': maxMembers,
      };

  GroupSettings copyWith({
    bool? isLocked,
    bool? onlyAdminsCanEditInfo,
    bool? onlyAdminsCanAddMembers,
    int? maxMembers,
    bool clearMaxMembers = false,
  }) {
    return GroupSettings(
      isLocked: isLocked ?? this.isLocked,
      onlyAdminsCanEditInfo:
          onlyAdminsCanEditInfo ?? this.onlyAdminsCanEditInfo,
      onlyAdminsCanAddMembers:
          onlyAdminsCanAddMembers ?? this.onlyAdminsCanAddMembers,
      maxMembers: clearMaxMembers ? null : (maxMembers ?? this.maxMembers),
    );
  }
}

class GroupModel {
  final String id;
  final String? name;
  final String? description;
  final String profileUrl;
  final List<GroupMember> groupMembers;
  final String createdAt;
  final String createdBy;
  final String timestamp;
  final String? lastMessage;
  final String? lastMessageTime;
  final String? lastMessageSenderId;
  final GroupSettings settings;

  List<UserModel> get members => groupMembers
      .map((gm) => UserModel(
            id: gm.odId,
            name: gm.name,
            profileimage: gm.profileImage,
            role: gm.role.name,
          ))
      .toList();

  GroupModel({
    required this.id,
    this.name,
    this.description,
    required this.profileUrl,
    required this.groupMembers,
    required this.createdAt,
    required this.createdBy,
    required this.timestamp,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.settings = const GroupSettings(),
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    List<GroupMember> parsedMembers = [];
    final rawMembers = json['members'];

    if (rawMembers is String) {
      try {
        final decoded = jsonDecode(rawMembers) as List<dynamic>;
        parsedMembers = decoded.map((e) {
          if (e is Map<String, dynamic>) {
            if (e.containsKey('userId')) {
              return GroupMember.fromJson(e);
            } else {
              return GroupMember(
                odId: e['id'] ?? '',
                name: e['name'] ?? '',
                profileImage: e['profileimage'],
                role: e['role']?.toString().toLowerCase() == 'admin'
                    ? MemberRole.admin
                    : MemberRole.member,
              );
            }
          }
          return GroupMember(odId: '', name: '');
        }).toList();
      } catch (_) {}
    } else if (rawMembers is List) {
      parsedMembers = rawMembers.map((e) {
        if (e is Map<String, dynamic>) {
          if (e.containsKey('userId')) {
            return GroupMember.fromJson(e);
          } else {
            return GroupMember(
              odId: e['id'] ?? '',
              name: e['name'] ?? '',
              profileImage: e['profileimage'],
              role: e['role']?.toString().toLowerCase() == 'admin'
                  ? MemberRole.admin
                  : MemberRole.member,
            );
          }
        }
        return GroupMember(odId: '', name: '');
      }).toList();
    }

    final createdBy = json['createdBy'] ?? '';
    for (int i = 0; i < parsedMembers.length; i++) {
      if (parsedMembers[i].odId == createdBy) {
        parsedMembers[i] = parsedMembers[i].copyWith(role: MemberRole.owner);
        break;
      }
    }

    GroupSettings settings;
    final rawSettings = json['settings'];
    if (rawSettings is String) {
      try {
        settings = GroupSettings.fromJson(jsonDecode(rawSettings));
      } catch (_) {
        settings = const GroupSettings();
      }
    } else if (rawSettings is Map<String, dynamic>) {
      settings = GroupSettings.fromJson(rawSettings);
    } else {
      settings = const GroupSettings();
    }

    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      profileUrl: json['profileUrl'] ?? '',
      groupMembers: parsedMembers,
      createdAt: json['createdAt'] ?? '',
      createdBy: createdBy,
      timestamp: json['timestamp'] ?? json['timeStamp'] ?? '',
      lastMessage: json['last_message'] ?? json['lastMessage'] ?? '',
      lastMessageTime: json['timeStamp'] ?? json['lastMessageTime'] ?? '',
      lastMessageSenderId: json['lastMessageSenderId'],
      settings: settings,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'profileUrl': profileUrl,
        'members': groupMembers.map((m) => m.toJson()).toList(),
        'createdAt': createdAt,
        'createdBy': createdBy,
        'timeStamp': timestamp,
        'last_message': lastMessage,
        'lastMessageSenderId': lastMessageSenderId,
        'settings': settings.toJson(),
      };

  bool isAdmin(String odId) {
    final member = groupMembers.firstWhereOrNull((m) => m.odId == odId);
    return member?.isAdmin ?? false;
  }

  bool isOwner(String odId) => createdBy == odId;

  bool isMember(String odId) {
    return groupMembers.any((m) => m.odId == odId);
  }

  bool canSendMessage(String odId) {
    if (!isMember(odId)) return false;

    final member = groupMembers.firstWhereOrNull((m) => m.odId == odId);
    if (member == null) return false;

    if (member.isMuted) {
      if (member.mutedUntil != null &&
          member.mutedUntil!.isBefore(DateTime.now())) {
        return true;
      }
      return false;
    }

    if (settings.isLocked) {
      return member.isAdmin;
    }

    return true;
  }

  bool canEditInfo(String odId) {
    if (isOwner(odId)) return true;
    if (!settings.onlyAdminsCanEditInfo) return isMember(odId);
    return isAdmin(odId);
  }

  bool canAddMembers(String odId) {
    if (isOwner(odId)) return true;
    if (!settings.onlyAdminsCanAddMembers) return isMember(odId);
    return isAdmin(odId);
  }

  bool canRemoveMember(String requesterId, String targetId) {
    if (targetId == createdBy) return false;
    if (isOwner(requesterId)) return true;
    if (!isAdmin(requesterId)) return false;

    return !isAdmin(targetId);
  }

  bool canPromoteToAdmin(String odId) => isOwner(odId);
  bool canDemoteAdmin(String odId) => isOwner(odId);

  int get adminCount => groupMembers.where((m) => m.isAdmin).length;
  int get memberCount => groupMembers.length;

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? profileUrl,
    List<GroupMember>? groupMembers,
    String? createdAt,
    String? createdBy,
    String? timestamp,
    String? lastMessage,
    String? lastMessageTime,
    String? lastMessageSenderId,
    GroupSettings? settings,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      profileUrl: profileUrl ?? this.profileUrl,
      groupMembers: groupMembers ?? this.groupMembers,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      timestamp: timestamp ?? this.timestamp,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      settings: settings ?? this.settings,
    );
  }
}

extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
