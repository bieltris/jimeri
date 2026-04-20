import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared/admin_page.dart';
import '../../core/shared/app_snackbar.dart';
import '../../core/shared/responsive_dialog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../models/payment_model.dart';
import 'payments_provider.dart';
import 'widgets/payment_form_dialog.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentsProvider);
    final selectedClient = state.selectedClient;

    return AdminPage(
      title: 'Pagamentos',
      description: 'Registre valores recebidos e acompanhe baixas por cliente.',
      action: FilledButton.icon(
        onPressed: selectedClient == null || state.isSaving
            ? null
            : () => _openPaymentForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Novo pagamento'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: state.selectedClientId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Cliente',
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: state.clients.map((item) {
              return DropdownMenuItem(
                value: item.client.id,
                child: Text('${item.client.name} - ${formatCents(item.balanceCents)}'),
              );
            }).toList(),
            onChanged: ref.read(paymentsProvider.notifier).selectClient,
          ),
          const SizedBox(height: 16),
          if (selectedClient != null)
            Text(
              'Divida atual: ${formatCents(selectedClient.balanceCents)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: selectedClient.balanceCents > 0
                        ? AppColors.error
                        : AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          const SizedBox(height: 24),
          if (state.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state.selectedClientId == null)
            const Text('Selecione um cliente para ver os pagamentos.')
          else if (state.payments.isEmpty)
            const Text('Nenhum pagamento registrado para este cliente.')
          else
            _PaymentsList(
              payments: state.payments,
              onCancel: (payment) => _cancelPayment(context, ref, payment),
            ),
        ],
      ),
    );
  }

  Future<void> _openPaymentForm(BuildContext context, WidgetRef ref) async {
    final input = await showDialog<PaymentFormInput>(
      context: context,
      builder: (context) => const PaymentFormDialog(),
    );

    if (input == null || !context.mounted) {
      return;
    }

    final error = await ref.read(paymentsProvider.notifier).createPayment(input);

    if (!context.mounted) {
      return;
    }

    if (error != null) {
      AppSnackBar.showError(error, context: context);
      return;
    }

    AppSnackBar.showSuccess('Pagamento registrado.', context: context);
  }

  Future<void> _cancelPayment(
    BuildContext context,
    WidgetRef ref,
    PaymentModel payment,
  ) async {
    final reason = await _askCancelReason(context);
    if (reason == null || !context.mounted) {
      return;
    }

    final error = await ref
        .read(paymentsProvider.notifier)
        .cancelPayment(payment, reason);

    if (!context.mounted) {
      return;
    }

    if (error != null) {
      AppSnackBar.showError(error, context: context);
      return;
    }

    AppSnackBar.showSuccess('Pagamento cancelado.', context: context);
  }

  Future<String?> _askCancelReason(BuildContext context) {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: const Text('Cancelar pagamento'),
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Motivo',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim();
              Navigator.of(context).pop(reason.isEmpty ? null : reason);
            },
            child: const Text('Cancelar pagamento'),
          ),
        ],
      ),
    );
  }
}

class _PaymentsList extends StatelessWidget {
  const _PaymentsList({
    required this.payments,
    required this.onCancel,
  });

  final List<PaymentModel> payments;
  final ValueChanged<PaymentModel> onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: payments.map((payment) {
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
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatCents(payment.amountCents),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: payment.cancelled
                                ? AppColors.neutral600
                                : AppColors.accent,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(payment.paymentMethod.label),
                    if (payment.note != null) Text(payment.note!),
                    if (payment.cancelled)
                      Text('Cancelado: ${payment.cancelReason ?? '-'}'),
                  ],
                ),
              ),
              if (!payment.cancelled)
                TextButton(
                  onPressed: () => onCancel(payment),
                  child: const Text('Cancelar'),
                )
              else
                const Text('Cancelado'),
            ],
          ),
        );
      }).toList(),
    );
  }
}
