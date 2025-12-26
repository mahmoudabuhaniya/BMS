class UserProfile {
  final String username;
  final String firstname;
  final String lastname;
  final String email;
  final List<String> groups;

  UserProfile({
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.groups,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json["username"] ?? "",
      firstname: json["firstname"] ?? "",
      lastname: json["lastname"] ?? "",
      email: json["email"] ?? "",
      groups: List<String>.from(json["groups"] ?? []),
    );
  }
}
