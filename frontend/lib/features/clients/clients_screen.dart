import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared/admin_page.dart';
import '../../core/shared/app_snackbar.dart';
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

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientsProvider);
    final clients = state.visibleClients;

    return AdminPage(
      title: 'Clientes',
      description: 'Cadastre clientes e acompanhe as dividas.',
      action: FilledButton.icon(
        onPressed: state.isSaving ? null : () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Novo cliente'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            const _EmptyClients()
          else
            _ClientsList(
              clients: clients,
              onEdit: (client) => _openForm(context, ref, client),
              onToggleStatus: (client) => _toggleStatus(context, ref, client),
              onCharge: (client) => _chargeClient(context, client),
              onPayment: (client) => _openPaymentForm(context, ref, client),
            ),
        ],
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, [
    ClientWithBalanceDto? client,
  ]) async {
    final input = await showDialog<ClientFormInput>(
      context: context,
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
        IconButton(
          tooltip: 'Atualizar',
          onPressed:
              state.isLoading ? null : ref.read(clientsProvider.notifier).loadClients,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _ClientsList extends StatelessWidget {
  const _ClientsList({
    required this.clients,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onCharge,
    required this.onPayment,
  });

  final List<ClientWithBalanceDto> clients;
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
                    Text(
                      client.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
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
                    onPressed: () => onEdit(item),
                    child: const Text('Editar'),
                  ),
                  if (hasDebt)
                    FilledButton.icon(
                      onPressed: () => onPayment(item),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Pagar'),
                    ),
                  if (hasDebt)
                    OutlinedButton.icon(
                      onPressed: _hasWhatsapp(client.responsibleWhatsapp)
                          ? () => onCharge(item)
                          : null,
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('Cobrar'),
                    ),
                  TextButton(
                    onPressed: () => onToggleStatus(item),
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

bool _hasWhatsapp(String? value) {
  return value != null && value.trim().isNotEmpty;
}

class _EmptyClients extends StatelessWidget {
  const _EmptyClients();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('Nenhum cliente encontrado.'),
      ),
    );
  }
}
