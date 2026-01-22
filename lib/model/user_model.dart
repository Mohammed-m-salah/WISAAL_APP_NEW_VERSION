// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 2)
class UserModel extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String? name;

  @HiveField(2)
  final String? email;

  @HiveField(3)
  final String? profileimage;

  @HiveField(4)
  final String? phonenumber;

  @HiveField(5)
  final String? about;

  @HiveField(6)
  final String? createdAt;

  @HiveField(7)
  final String? lastOnlineStatus;

  @HiveField(8)
  final bool? status;

  @HiveField(9)
  final String? role;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.profileimage,
    this.phonenumber,
    this.about,
    this.createdAt,
    this.lastOnlineStatus,
    this.status,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] as String?,
      email: json['email'],
      profileimage: json['profileimage'],
      phonenumber: json['phonenumber'],
      about: json['about'],
      createdAt: json['createdAt'],
      lastOnlineStatus: json['lastOnlineStatus'],
      status: json['status'],
      role: json['Role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileimage': profileimage,
      'phonenumber': phonenumber,
      'about': about ?? '',
      'createdAt': createdAt,
      'lastOnlineStatus': lastOnlineStatus,
      'status': status,
      'Role': role,
    };
  }
}
