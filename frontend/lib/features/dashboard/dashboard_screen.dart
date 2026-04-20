import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      const _DashboardAction(
        title: 'Clientes',
        description: 'Cadastrar e consultar dividas',
        icon: Icons.people_alt_outlined,
        route: '/clients',
      ),
      const _DashboardAction(
        title: 'Produtos',
        description: 'Itens, categorias e precos',
        icon: Icons.inventory_2_outlined,
        route: '/products',
      ),
      const _DashboardAction(
        title: 'Pedidos',
        description: 'Marcar compras do dia',
        icon: Icons.receipt_long_outlined,
        route: '/orders',
      ),
      const _DashboardAction(
        title: 'Pagamentos',
        description: 'Registrar valores recebidos',
        icon: Icons.payments_outlined,
        route: '/payments',
      ),
      const _DashboardAction(
        title: 'Relatorios',
        description: 'Ver saldos e movimento',
        icon: Icons.bar_chart_outlined,
        route: '/reports',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jimeri',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escolha uma area para continuar.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Atalhos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 720 ? 3 : 1;

                      return GridView.builder(
                        itemCount: actions.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: columns == 1 ? 4.2 : 2.4,
                        ),
                        itemBuilder: (context, index) {
                          return _DashboardButton(action: actions[index]);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardButton extends StatelessWidget {
  const _DashboardButton({
    required this.action,
  });

  final _DashboardAction action;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => context.go(action.route),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        side: const BorderSide(color: AppColors.neutral300),
        padding: const EdgeInsets.all(16),
      ),
      child: Row(
        children: [
          Icon(action.icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  action.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  action.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAction {
  const _DashboardAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
  });

  final String title;
  final String description;
  final IconData icon;
  final String route;
}
