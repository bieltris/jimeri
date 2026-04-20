import '../api/api_auth_delegate.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/api_routes.dart';
import '../../dtos/auth_response_dto.dart';
import '../../models/user_model.dart';

class AuthService implements ApiAuthDelegate {
  String? _accessToken;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _accessToken != null && _currentUser != null;

  @override
  String? get accessToken => _accessToken;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post<AuthResponseDto>(
      ApiRoutes.login(),
      body: {
        'email': email,
        'password': password,
      },
      fromJson: AuthResponseDto.fromJson,
    );

    _setSession(response);

    return response.user;
  }

  Future<UserModel> loadCurrentUser() async {
    final user = await ApiClient.get<UserModel>(
      ApiRoutes.me(),
      fromJson: UserModel.fromJson,
    );

    _currentUser = user;

    return user;
  }

  @override
  Future<String?> refreshAccessToken() async {
    try {
      final response = await ApiClient.post<AuthResponseDto>(
        ApiRoutes.refresh(),
        fromJson: AuthResponseDto.fromJson,
      );

      _setSession(response);

      return response.accessToken;
    } on ApiException {
      _clearSession();

      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await ApiClient.post<void>(ApiRoutes.logout());
    } on ApiException {
      // A sessao local precisa cair mesmo se o backend nao responder.
    } finally {
      _clearSession();
    }
  }

  @override
  bool shouldSkipAuth(Uri uri) {
    return uri.path.endsWith('/auth/login') ||
        uri.path.endsWith('/auth/refresh') ||
        uri.path.endsWith('/auth/logout');
  }

  void _setSession(AuthResponseDto response) {
    _accessToken = response.accessToken;
    _currentUser = response.user;
  }

  void _clearSession() {
    _accessToken = null;
    _currentUser = null;
  }
}
