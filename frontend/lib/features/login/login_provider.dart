import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_providers.dart';

final loginProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);

class LoginState {
  const LoginState({
    this.isLoading = false,
  });

  final bool isLoading;

  LoginState copyWith({
    bool? isLoading,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() {
    return const LoginState();
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty || password.isEmpty) {
      return 'Informe email e senha.';
    }

    state = state.copyWith(isLoading: true);

    try {
      await ref.read(authServiceProvider).login(
            email: normalizedEmail,
            password: password,
          );

      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
