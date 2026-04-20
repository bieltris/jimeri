import '../models/user_model.dart';

class AuthResponseDto {
  const AuthResponseDto({
    required this.accessToken,
    required this.user,
  });

  final String accessToken;
  final UserModel user;

  factory AuthResponseDto.fromJson(dynamic json) {
    final data = json as Map<String, dynamic>;

    return AuthResponseDto(
      accessToken: data['accessToken'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}
