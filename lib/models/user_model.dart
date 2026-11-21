class UserModel {
  final int id;
  final String email;
  final String username;
  final String preferredLocale;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.preferredLocale,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      preferredLocale: (json['preferred_locale'] as String?) ?? 'uk',
    );
  }

  UserModel copyWith({
    String? username,
    String? preferredLocale,
  }) {
    return UserModel(
      id: id,
      email: email,
      username: username ?? this.username,
      preferredLocale: preferredLocale ?? this.preferredLocale,
    );
  }
}