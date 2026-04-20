import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_service.dart';

class LoginProvider extends ChangeNotifier {
  LoginProvider({
    required AuthService authService,
  }) : _authService = authService;

  final AuthService _authService;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty || password.isEmpty) {
      return 'Informe email e senha.';
    }

    _setLoading(true);

    try {
      await _authService.login(
        email: normalizedEmail,
        password: password,
      );

      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }
}
