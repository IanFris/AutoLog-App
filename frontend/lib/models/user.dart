class User {
  final int id;
  final String name;
  final String email;
  final String? token;
  final bool isGuest;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.token,
    this.isGuest = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      token: json['token'] as String?,
      isGuest: json['is_guest'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'token': token,
      'is_guest': isGuest,
    };
  }
}
