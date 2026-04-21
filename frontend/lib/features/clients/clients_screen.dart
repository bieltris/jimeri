import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared/admin_page.dart';
import '../../core/shared/app_snackbar.dart';
import '../../core/shared/page_feedback.dart';
import '../../core/platform/open_external_url.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../dtos/client_with_balance_dto.dart';
import '../../services/clients_service.dart';
import '../../services/payments_service.dart';
import '../payments/payments_provider.dart';
import '../payments/widgets/payment_form_dialog.dart';
import 'clients_provider.dart';
import 'widgets/client_form_dialog.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(ref.read(clientsProvider.notifier).loadClients);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientsProvider);
    final clients = state.visibleClients;

    return AdminPage(
      title: 'Clientes',
      description: 'Cadastre clientes e acompanhe as dividas.',
      onRefresh: _refreshPage,
      action: FilledButton.icon(
        onPressed: state.isSaving ? null : () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Novo cliente'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.error != null) ...[
            PageFeedbackCard(
              title: 'Falha ao carregar clientes',
              message: state.error!,
              tone: PageFeedbackTone.error,
              actionLabel: 'Tentar novamente',
              onAction: state.isLoading
                  ? null
                  : ref.read(clientsProvider.notifier).loadClients,
            ),
            const SizedBox(height: 16),
          ],
          _ClientFilters(state: state),
          const SizedBox(height: 20),
          if (state.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (clients.isEmpty)
            _EmptyClients(state: state)
          else
            _ClientsList(
              clients: clients,
              isBusy: state.isSaving || state.isLoading,
              onEdit: (client) => _openForm(context, ref, client),
              onToggleStatus: (client) => _toggleStatus(context, ref, client),
              onCharge: (client) => _chargeClient(context, client),
              onPayment: (client) => _openPaymentForm(context, ref, client),
            ),
        ],
      ),
    );
  }

  Future<void> _refreshPage() {
    return ref.read(clientsProvider.notifier).loadClients();
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, [
    ClientWithBalanceDto? client,
  ]) async {
    final input = await showDialog<ClientFormInput>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ClientFormDialog(client: client),
    );

    if (input == null || !context.mounted) {
      return;
    }

    final error = client == null
        ? await ref.read(clientsProvider.notifier).createClient(input)
        : await ref.read(clientsProvider.notifier).updateClient(client, input);

    if (!context.mounted) {
      return;
    }

    if (error != null) {
      AppSnackBar.showError(error, context: context);
      return;
    }

    AppSnackBar.showSuccess(
      client == null ? 'Cliente criado.' : 'Cliente atualizado.',
      context: context,
    );
  }

  Future<void> _toggleStatus(
    BuildContext context,
    WidgetRef ref,
    ClientWithBalanceDto client,
  ) async {
    final error =
        await ref.read(clientsProvider.notifier).toggleClientStatus(client);

    if (!context.mounted) {
      return;
    }

    if (error != null) {
      AppSnackBar.showError(error, context: context);
      return;
    }

    AppSnackBar.showSuccess(
      client.client.active ? 'Cliente desativado.' : 'Cliente ativado.',
      context: context,
    );
  }

  Future<void> _chargeClient(
    BuildContext context,
    ClientWithBalanceDto client,
  ) async {
    try {
      final charge = await ClientsService().whatsappCharge(client.client.id);

      if (!context.mounted) {
        return;
      }

      openExternalUrl(charge.url);
      AppSnackBar.showSuccess('Cobranca aberta no WhatsApp.', context: context);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      AppSnackBar.showError(
        'Nao foi possivel abrir a cobranca. Confira WhatsApp e divida.',
        context: context,
      );
    }
  }

  Future<void> _openPaymentForm(
    BuildContext context,
    WidgetRef ref,
    ClientWithBalanceDto client,
  ) async {
    final input = await showDialog<PaymentFormInput>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PaymentFormDialog(),
    );

    if (input == null || !context.mounted) {
      return;
    }

    try {
      await PaymentsService().create(
        clientId: client.client.id,
        amountCents: input.amountCents,
        paymentMethod: input.paymentMethod,
        note: input.note,
      );

      await ref.read(clientsProvider.notifier).loadClients();

      if (!context.mounted) {
        return;
      }

      AppSnackBar.showSuccess('Pagamento registrado.', context: context);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      AppSnackBar.showError('Nao foi possivel registrar o pagamento.', context: context);
    }
  }
}

class _ClientFilters extends ConsumerWidget {
  const _ClientFilters({
    required this.state,
  });

  final ClientsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 360,
          child: TextField(
            onChanged: ref.read(clientsProvider.notifier).setSearch,
            decoration: const InputDecoration(
              labelText: 'Buscar cliente',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        SegmentedButton<ClientsFilter>(
          segments: const [
            ButtonSegment(value: ClientsFilter.all, label: Text('Todos')),
            ButtonSegment(value: ClientsFilter.active, label: Text('Ativos')),
            ButtonSegment(value: ClientsFilter.inactive, label: Text('Inativos')),
            ButtonSegment(value: ClientsFilter.withDebt, label: Text('Com divida')),
          ],
          selected: {state.filter},
          onSelectionChanged: (values) {
            ref.read(clientsProvider.notifier).setFilter(values.first);
          },
        ),
      ],
    );
  }
}

class _ClientsList extends StatelessWidget {
  const _ClientsList({
    required this.clients,
    required this.isBusy,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onCharge,
    required this.onPayment,
  });

  final List<ClientWithBalanceDto> clients;
  final bool isBusy;
  final ValueChanged<ClientWithBalanceDto> onEdit;
  final ValueChanged<ClientWithBalanceDto> onToggleStatus;
  final ValueChanged<ClientWithBalanceDto> onCharge;
  final ValueChanged<ClientWithBalanceDto> onPayment;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: clients.map((item) {
        final client = item.client;
        final hasDebt = item.balanceCents > 0;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: AppColors.neutral200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 360,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            client.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ClientStatusBadge(active: client.active),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(client.responsibleName ?? 'Sem responsavel informado'),
                    if (client.responsibleWhatsapp != null)
                      Text('WhatsApp: ${client.responsibleWhatsapp}'),
                  ],
                ),
              ),
              Text(
                formatCents(item.balanceCents),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: hasDebt ? AppColors.error : AppColors.accent,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: isBusy ? null : () => onEdit(item),
                    child: const Text('Editar'),
                  ),
                  if (hasDebt)
                    FilledButton.icon(
                      onPressed: isBusy ? null : () => onPayment(item),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Pagar'),
                    ),
                  if (hasDebt)
                    OutlinedButton.icon(
                      onPressed: !isBusy && _hasWhatsapp(client.responsibleWhatsapp)
                          ? () => onCharge(item)
                          : null,
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('Cobrar'),
                    ),
                  TextButton(
                    onPressed: isBusy ? null : () => onToggleStatus(item),
                    child: Text(client.active ? 'Desativar' : 'Ativar'),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ClientStatusBadge extends StatelessWidget {
  const _ClientStatusBadge({
    required this.active,
  });

  final bool active;

  @override
  Widget build(BuildContext context) {
    final background = active ? AppColors.accentLight : AppColors.neutral200;
    final foreground = active ? AppColors.accentDark : AppColors.neutral600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        active ? 'Cliente ativo' : 'Cliente inativo',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

bool _hasWhatsapp(String? value) {
  return value != null && value.trim().isNotEmpty;
}

class _EmptyClients extends StatelessWidget {
  const _EmptyClients({
    required this.state,
  });

  final ClientsState state;

  @override
  Widget build(BuildContext context) {
    final isFiltering =
        state.search.trim().isNotEmpty || state.filter != ClientsFilter.active;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: PageFeedbackCard(
        title: isFiltering ? 'Nenhum cliente encontrado' : 'Nenhum cliente cadastrado',
        message: isFiltering
            ? 'Ajuste a busca ou o filtro para encontrar um cliente.'
            : 'Cadastre o primeiro cliente para comecar a acompanhar as dividas.',
      ),
    );
  }
}
