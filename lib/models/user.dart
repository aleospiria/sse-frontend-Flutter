enum UserRole { admin, coordinador, operario, auditor }

class User {
  final String id;
  final String username;
  final String name;
  final String? email;
  final UserRole role;
  final String? industry;

  const User({
    required this.id,
    required this.username,
    required this.name,
    this.email,
    required this.role,
    this.industry,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.operario,
      ),
      industry: json['industry'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'email': email,
        'role': role.name,
        'industry': industry,
      };

  bool get isAdmin => role == UserRole.admin;
  bool get isCoordinador => role == UserRole.coordinador;
  bool get isOperario => role == UserRole.operario;
  bool get isAuditor => role == UserRole.auditor;
}
