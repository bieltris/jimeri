import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final authService = AuthService();

  configureApiClient(auth: authService);
  ref.onDispose(authService.dispose);

  return authService;
});
