import 'package:hive_flutter/hive_flutter.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 2)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String username;

  @HiveField(1)
  final String firstName;

  @HiveField(2)
  final String lastName;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String groups; // stored as a single string

  @HiveField(5)
  final String fullName; // computed once

  UserProfile({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.groups,
    required this.fullName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final grp = json["groups"];

    // Convert list → string
    String groupStr;
    if (grp is List) {
      groupStr = grp.join(", "); // ["Admin"] → "Admin"
    } else if (grp is String) {
      groupStr = grp; // "Admin"
    } else {
      groupStr = "";
    }

    return UserProfile(
      username: json["username"] ?? "",
      firstName: json["first_name"] ?? "",
      lastName: json["last_name"] ?? "",
      email: json["email"] ?? "",
      groups: groupStr,
      fullName: json["full_name"],
    );
  }
}
