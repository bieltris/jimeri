import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/auth/auth_service.dart';

void main() {
  final authService = AuthService();

  configureApiClient(auth: authService);

  runApp(JimeriApp(authService: authService));
}
