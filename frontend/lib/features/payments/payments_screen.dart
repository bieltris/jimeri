import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared/admin_page.dart';
import '../../core/shared/adaptive_form_sheet.dart';
import '../../core/shared/app_snackbar.dart';
import '../../core/shared/page_feedback.dart';
import '../../core/shared/responsive_dialog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../dtos/client_with_balance_dto.dart';
import '../../models/payment_model.dart';
import 'payments_provider.dart';
import 'widgets/payment_form_dialog.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(ref.read(paymentsProvider.notifier).loadClients);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentsProvider);
    final selectedClient = state.selectedClient;

    return AdminPage(
      title: 'Pagamentos',
      description: 'Registre valores recebidos e acompanhe baixas por cliente.',
      onRefresh: _refreshPage,
      action: FilledButton.icon(
        onPressed: selectedClient == null || state.isSaving || state.isLoading
            ? null
            : () => _openPaymentForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Novo pagamento'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.error != null) ...[
            PageFeedbackCard(
              title: 'Falha ao carregar pagamentos',
              message: state.error!,
              tone: PageFeedbackTone.error,
              actionLabel: 'Atualizar',
              onAction: state.isLoading
                  ? null
                  : ref.read(paymentsProvider.notifier).reloadSelectedClient,
            ),
            const SizedBox(height: 16),
          ],
          _PaymentsClientPicker(state: state),
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
            const PageFeedbackCard(
              title: 'Selecione um cliente',
              message: 'Escolha um cliente para consultar e registrar pagamentos.',
            )
          else if (state.payments.isEmpty)
            const PageFeedbackCard(
              title: 'Nenhum pagamento registrado',
              message: 'Esse cliente ainda nao possui pagamentos cadastrados.',
            )
          else
            _PaymentsList(
              payments: state.payments,
              onCancel: state.isSaving
                  ? null
                  : (payment) => _cancelPayment(context, ref, payment),
            ),
        ],
      ),
    );
  }

  Future<void> _refreshPage() {
    return ref.read(paymentsProvider.notifier).reloadSelectedClient();
  }

  Future<void> _openPaymentForm(BuildContext context, WidgetRef ref) async {
    final input = await showAdaptiveFormSheet<PaymentFormInput>(
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
      barrierDismissible: false,
      builder: (context) => ResponsiveDialog(
        title: const Text('Cancelar pagamento'),
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Motivo',
          ),
        ),
        actions: [
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
  final ValueChanged<PaymentModel>? onCancel;

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
                  onPressed: onCancel == null ? null : () => onCancel!(payment),
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

class _PaymentsClientPicker extends ConsumerStatefulWidget {
  const _PaymentsClientPicker({
    required this.state,
  });

  final PaymentsState state;

  @override
  ConsumerState<_PaymentsClientPicker> createState() =>
      _PaymentsClientPickerState();
}

class _PaymentsClientPickerState extends ConsumerState<_PaymentsClientPicker> {
  final _pickerKey = GlobalKey();
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    _syncSelectedClientName();
  }

  @override
  void didUpdateWidget(covariant _PaymentsClientPicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldClientId = oldWidget.state.selectedClientId;
    final newClientId = widget.state.selectedClientId;
    if (oldClientId != newClientId) {
      _syncSelectedClientName();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.state.isSaving;

    return Container(
      key: _pickerKey,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cliente',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          RawAutocomplete<ClientWithBalanceDto>(
            textEditingController: _searchController,
            focusNode: _focusNode,
            displayStringForOption: (option) => option.client.name,
            optionsBuilder: (textEditingValue) {
              if (!enabled) {
                return const Iterable<ClientWithBalanceDto>.empty();
              }

              final rawQuery = textEditingValue.text.trim();
              if (rawQuery.isEmpty) {
                return const Iterable<ClientWithBalanceDto>.empty();
              }

              final query = rawQuery.toLowerCase();
              final scored = <({int score, ClientWithBalanceDto item})>[];

              for (final item in widget.state.clients) {
                final name = item.client.name.toLowerCase();
                final responsibleName =
                    (item.client.responsibleName ?? '').toLowerCase();
                final whatsapp =
                    (item.client.responsibleWhatsapp ?? '').toLowerCase();

                int? score;
                if (name.startsWith(query)) {
                  score = 0;
                } else if (name.contains(query)) {
                  score = 1;
                } else if (responsibleName.contains(query)) {
                  score = 2;
                } else if (whatsapp.contains(query)) {
                  score = 3;
                }

                if (score != null) {
                  scored.add((score: score, item: item));
                }
              }

              scored.sort((a, b) {
                final byScore = a.score.compareTo(b.score);
                if (byScore != 0) {
                  return byScore;
                }

                return a.item.client.name.compareTo(b.item.client.name);
              });

              return scored.take(5).map((entry) => entry.item);
            },
            onSelected: (option) {
              ref
                  .read(paymentsProvider.notifier)
                  .selectClient(option.client.id);
              _searchController.value = TextEditingValue(
                text: option.client.name,
                selection: TextSelection.collapsed(
                  offset: option.client.name.length,
                ),
              );
              _focusNode.unfocus();
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                onChanged: (value) {
                  final selected = widget.state.selectedClient;
                  if (selected != null && value.trim() != selected.client.name) {
                    ref.read(paymentsProvider.notifier).selectClient(null);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Buscar por aluno, mae ou WhatsApp',
                  prefixIcon: Icon(Icons.person_search),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              final items = options.toList(growable: false);
              if (items.isEmpty) {
                return const SizedBox.shrink();
              }

              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 640,
                      maxHeight: 280,
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final subtitle = item.client.responsibleName ??
                            item.client.responsibleWhatsapp ??
                            'Sem responsavel informado';

                        return ListTile(
                          dense: true,
                          title: Text(item.client.name),
                          subtitle: Text(
                            subtitle,
                            style: const TextStyle(
                              color: AppColors.neutral300MediumAlpha,
                            ),
                          ),
                          trailing: Text(
                            formatCents(item.balanceCents),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: item.balanceCents > 0
                                      ? AppColors.error
                                      : AppColors.accent,
                                ),
                          ),
                          onTap: () => onSelected(item),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _syncSelectedClientName() {
    final selected = widget.state.selectedClient;
    if (selected == null) {
      if (!_focusNode.hasFocus) {
        _searchController.clear();
      }
      return;
    }

    _searchController.value = TextEditingValue(
      text: selected.client.name,
      selection: TextSelection.collapsed(offset: selected.client.name.length),
    );
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _pickerKey.currentContext;
      if (context == null || !mounted) {
        return;
      }

      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: 0,
      );
    });
  }
}
