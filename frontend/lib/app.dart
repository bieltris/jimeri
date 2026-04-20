import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/auth/auth_service.dart';
import 'core/shared/app_snackbar.dart';
import 'features/login/login_provider.dart';
import 'features/login/login_screen.dart';

class JimeriApp extends StatelessWidget {
  const JimeriApp({
    required this.authService,
    super.key,
  });

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider(
          create: (_) => LoginProvider(authService: authService),
        ),
      ],
      child: MaterialApp(
        title: 'Jimeri',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            primary: const Color(0xFF2563EB),
            secondary: const Color(0xFF16A34A),
            surface: const Color(0xFFF8FAFC),
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
