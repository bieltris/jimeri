import 'package:flutter/foundation.dart';

import '../api/api_auth_delegate.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/api_routes.dart';
import '../../dtos/auth_response_dto.dart';
import '../../models/user_model.dart';
import 'refresh_token_store.dart';

class AuthService extends ChangeNotifier implements ApiAuthDelegate {
  AuthService({
    RefreshTokenStore? refreshTokenStore,
  }) : _refreshTokenStore = refreshTokenStore ?? createRefreshTokenStore();

  String? _accessToken;
  UserModel? _currentUser;
  bool _isCheckingSession = false;
  final RefreshTokenStore _refreshTokenStore;

  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _accessToken != null && _currentUser != null;

  bool get isCheckingSession => _isCheckingSession;

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

    await _persistSession(response);

    return response.user;
  }

  Future<bool> tryAutoLogin() async {
    if (isAuthenticated) {
      return true;
    }

    _setCheckingSession(true);

    try {
      final refreshToken = await _refreshTokenStore.read();
      final response = await ApiClient.post<AuthResponseDto>(
        ApiRoutes.refresh(),
        body: refreshToken == null
            ? null
            : {
                'refreshToken': refreshToken,
              },
        fromJson: AuthResponseDto.fromJson,
      );

      await _persistSession(response);

      return true;
    } on ApiException {
      await _clearSession(notify: false);

      return false;
    } finally {
      _setCheckingSession(false);
    }
  }

  Future<UserModel> loadCurrentUser() async {
    final user = await ApiClient.get<UserModel>(
      ApiRoutes.me(),
      fromJson: UserModel.fromJson,
    );

    _currentUser = user;
    notifyListeners();

    return user;
  }

  @override
  Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await _refreshTokenStore.read();
      final response = await ApiClient.post<AuthResponseDto>(
        ApiRoutes.refresh(),
        body: refreshToken == null
            ? null
            : {
                'refreshToken': refreshToken,
              },
        fromJson: AuthResponseDto.fromJson,
      );

      await _persistSession(response);

      return response.accessToken;
    } on ApiException {
      await _clearSession();

      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await _refreshTokenStore.read();
      await ApiClient.post<void>(
        ApiRoutes.logout(),
        body: refreshToken == null
            ? null
            : {
                'refreshToken': refreshToken,
              },
      );
    } on ApiException {
      // A sessao local precisa cair mesmo se o backend nao responder.
    } finally {
      await _clearSession();
    }
  }

  @override
  bool shouldSkipAuth(Uri uri) {
    return uri.path.endsWith('/auth/login') ||
        uri.path.endsWith('/auth/refresh') ||
        uri.path.endsWith('/auth/logout');
  }

  Future<void> _persistSession(AuthResponseDto response) async {
    await _refreshTokenStore.write(response.refreshToken);
    _setSession(response);
  }

  void _setSession(AuthResponseDto response) {
    _accessToken = response.accessToken;
    _currentUser = response.user;
    notifyListeners();
  }

  Future<void> _clearSession({bool notify = true}) async {
    await _refreshTokenStore.clear();
    _accessToken = null;
    _currentUser = null;

    if (notify) {
      notifyListeners();
    }
  }

  void _setCheckingSession(bool value) {
    if (_isCheckingSession == value) {
      return;
    }

    _isCheckingSession = value;
    notifyListeners();
  }
}
