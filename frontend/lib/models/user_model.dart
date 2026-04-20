class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String role;

  factory UserModel.fromJson(dynamic json) {
    final data = json as Map<String, dynamic>;

    return UserModel(
      id: data['id'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      role: data['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
    };
  }
}
