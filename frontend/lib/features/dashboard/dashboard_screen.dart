import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/shared/page_feedback.dart';
import '../../core/shared/responsive_dialog.dart';
import '../../core/shared/skeleton_box.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../dtos/client_with_balance_dto.dart';
import '../../services/clients_service.dart';

final dashboardClientsProvider =
    FutureProvider<List<ClientWithBalanceDto>>((ref) {
  return ClientsService().list();
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(dashboardClientsProvider));
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(dashboardClientsProvider);
    final clients = clientsAsync.value ?? const <ClientWithBalanceDto>[];
    final debtors = clients.where((item) => item.balanceCents > 0).toList()
      ..sort((left, right) => right.balanceCents.compareTo(left.balanceCents));
    final totalDebtCents = clients.fold<int>(
      0,
      (total, item) => total + (item.balanceCents > 0 ? item.balanceCents : 0),
    );
    final clientsWithDebt = clients
        .where(
          (item) => item.balanceCents > 0,
        )
        .length;
    final activeClients = clients
        .where(
          (item) => item.client.active,
        )
        .length;

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
        title: 'Registrar Pedidos',
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
    ];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshPage,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jimeri',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      color: AppColors.primary,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _greeting(),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (clientsAsync.hasError) ...[
                      const SizedBox(height: 24),
                      PageFeedbackCard(
                        title: 'Falha ao carregar o painel',
                        message: 'Nao foi possivel buscar os dados agora.',
                        tone: PageFeedbackTone.error,
                        actionLabel: 'Tentar novamente',
                        onAction: () =>
                            ref.invalidate(dashboardClientsProvider),
                      ),
                    ],
                    const SizedBox(height: 32),
                    _DashboardSummary(
                      isLoading: clientsAsync.isLoading,
                      totalDebtCents: totalDebtCents,
                      clientsWithDebt: clientsWithDebt,
                      activeClients: activeClients,
                      onOpenDebtors: debtors.isEmpty
                          ? null
                          : () => _showDebtorsDialog(
                                context,
                                debtors: debtors,
                                totalDebtCents: totalDebtCents,
                              ),
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: columns == 1 ? 96 : 104,
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
      ),
    );
  }

  Future<void> _refreshPage() async {
    return await ref.refresh(dashboardClientsProvider.future);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia! Escolha uma area para continuar.';
    if (hour < 18) return 'Boa tarde! Escolha uma area para continuar.';
    return 'Boa noite! Escolha uma area para continuar.';
  }

  Future<void> _showDebtorsDialog(
    BuildContext context, {
    required List<ClientWithBalanceDto> debtors,
    required int totalDebtCents,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ResponsiveDialog(
          maxWidth: 520,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dividas em aberto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                '${debtors.length} ${debtors.length == 1 ? 'cliente devendo' : 'clientes devendo'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          actions: const [],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: AppColors.neutral300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total em aberto',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Divider(),
                    Text(
                      formatCents(totalDebtCents),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...debtors.map(
                (debtor) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DebtorTile(item: debtor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardSummary extends StatelessWidget {
  const _DashboardSummary({
    required this.isLoading,
    required this.totalDebtCents,
    required this.clientsWithDebt,
    required this.activeClients,
    required this.onOpenDebtors,
  });

  final bool isLoading;
  final int totalDebtCents;
  final int clientsWithDebt;
  final int activeClients;
  final VoidCallback? onOpenDebtors;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 3 : 1;

        if (isLoading) {
          return GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: columns == 1 ? 92 : 112,
            ),
            children: List.generate(3, (_) => const _SummaryCardSkeleton()),
          );
        }

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: columns == 1 ? 92 : 112,
          ),
          children: [
            _SummaryCard(
              title: 'Total em aberto',
              value: formatCents(totalDebtCents),
              color: totalDebtCents > 0 ? AppColors.error : AppColors.accent,
              onPressed: onOpenDebtors,
            ),
            _SummaryCard(
              title: 'Clientes devendo',
              value: clientsWithDebt.toString(),
              color: clientsWithDebt > 0 ? AppColors.warning : AppColors.accent,
            ),
            _SummaryCard(
              title: 'Clientes ativos',
              value: activeClients.toString(),
              color: AppColors.primary,
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    this.onPressed,
  });

  final String title;
  final String value;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final iconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    final inner = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(width: 4, color: color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (onPressed != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.arrow_forward_rounded, color: iconColor),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (onPressed == null) {
      return Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: AppColors.neutral300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: inner,
      );
    }

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutral300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: inner,
        ),
      ),
    );
  }
}

class _SummaryCardSkeleton extends StatelessWidget {
  const _SummaryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.neutral300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SkeletonBox(width: 100, height: 13),
          SizedBox(height: 10),
          SkeletonBox(width: 140, height: 24),
        ],
      ),
    );
  }
}

class _DashboardButton extends StatelessWidget {
  final _DashboardAction action;

  const _DashboardButton({
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => context.push(action.route),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        side: const BorderSide(color: AppColors.neutral300),
        padding: const EdgeInsets.all(16),
      ),
      child: Row(
        children: [
          Icon(
            action.icon,
            color: AppColors.primary,
            size: 22,
          ),
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

class _DebtorTile extends StatelessWidget {
  const _DebtorTile({
    required this.item,
  });

  final ClientWithBalanceDto item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.neutral300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.client.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatCents(item.balanceCents),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w800,
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
