import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/clients/clients_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/login/login_screen.dart';
import '../../features/payments/payments_screen.dart';
import '../../features/placeholder/placeholder_screen.dart';
import '../../features/products/products_screen.dart';
import '../auth/auth_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authService,
    redirect: (context, state) {
      final isLoginRoute = state.matchedLocation == '/login';

      if (authService.isCheckingSession) {
        return isLoginRoute ? null : '/login';
      }

      if (!authService.isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      if (authService.isAuthenticated && isLoginRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/clients',
        builder: (context, state) => const ClientsScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Pedidos',
          description: 'Registro das compras feitas pelos clientes.',
        ),
      ),
      GoRoute(
        path: '/payments',
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Relatorios',
          description: 'Resumo simples da cantina e das dividas em aberto.',
        ),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) => '/dashboard',
      ),
    ],
  );
});
