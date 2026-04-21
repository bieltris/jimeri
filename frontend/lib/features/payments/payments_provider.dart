import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../dtos/client_with_balance_dto.dart';
import '../../models/payment_model.dart';
import '../../services/payments_service.dart';
import '../clients/clients_provider.dart';

final paymentsServiceProvider = Provider<PaymentsService>((ref) {
  return PaymentsService();
});

final paymentsProvider = NotifierProvider<PaymentsController, PaymentsState>(
  PaymentsController.new,
);

class PaymentsState {
  const PaymentsState({
    this.clients = const [],
    this.payments = const [],
    this.selectedClientId,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final List<ClientWithBalanceDto> clients;
  final List<PaymentModel> payments;
  final String? selectedClientId;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  ClientWithBalanceDto? get selectedClient {
    for (final client in clients) {
      if (client.client.id == selectedClientId) {
        return client;
      }
    }

    return null;
  }

  PaymentsState copyWith({
    List<ClientWithBalanceDto>? clients,
    List<PaymentModel>? payments,
    String? selectedClientId,
    bool clearSelectedClient = false,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return PaymentsState(
      clients: clients ?? this.clients,
      payments: payments ?? this.payments,
      selectedClientId:
          clearSelectedClient ? null : selectedClientId ?? this.selectedClientId,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class PaymentFormInput {
  const PaymentFormInput({
    required this.amountCents,
    required this.paymentMethod,
    this.note,
  });

  final int amountCents;
  final PaymentMethod paymentMethod;
  final String? note;
}

class PaymentsController extends Notifier<PaymentsState> {
  @override
  PaymentsState build() {
    Future.microtask(loadClients);
    return const PaymentsState(isLoading: true);
  }

  Future<void> loadClients() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final clients = await ref.read(clientsServiceProvider).list();
      state = state.copyWith(
        clients: clients,
        isLoading: false,
        clearError: true,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
    }
  }

  Future<void> reloadSelectedClient() async {
    final clientId = state.selectedClientId;
    if (clientId == null || clientId.isEmpty) {
      await loadClients();
      return;
    }

    await loadClients();
    await selectClient(clientId);
  }

  Future<void> selectClient(String? clientId) async {
    if (clientId == null || clientId.isEmpty) {
      state = state.copyWith(
        payments: const [],
        clearSelectedClient: true,
      );
      return;
    }

    state = state.copyWith(
      selectedClientId: clientId,
      isLoading: true,
      clearError: true,
    );

    try {
      final payments = await ref.read(paymentsServiceProvider).listByClient(clientId);

      state = state.copyWith(
        payments: payments,
        isLoading: false,
        clearError: true,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
    }
  }

  Future<String?> createPayment(PaymentFormInput input) async {
    final client = state.selectedClient;
    if (client == null) {
      return 'Selecione um cliente.';
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final payment = await ref.read(paymentsServiceProvider).create(
            clientId: client.client.id,
            amountCents: input.amountCents,
            paymentMethod: input.paymentMethod,
            note: input.note,
          );

      final updatedClient = ClientWithBalanceDto(
        client: client.client,
        balanceCents: client.balanceCents - payment.amountCents,
      );

      state = state.copyWith(
        payments: [payment, ...state.payments],
        clients: _replaceClient(updatedClient),
        isSaving: false,
        clearError: true,
      );

      return null;
    } on ApiException catch (error) {
      state = state.copyWith(isSaving: false, error: error.message);
      return error.message;
    }
  }

  Future<String?> cancelPayment(PaymentModel payment, String reason) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final updated = await ref.read(paymentsServiceProvider).cancel(
            id: payment.id,
            reason: reason,
          );

      state = state.copyWith(
        payments: state.payments.map((current) {
          return current.id == updated.id ? updated : current;
        }).toList(),
        isSaving: false,
        clearError: true,
      );

      await loadClients();
      await selectClient(state.selectedClientId);

      return null;
    } on ApiException catch (error) {
      state = state.copyWith(isSaving: false, error: error.message);
      return error.message;
    }
  }

  List<ClientWithBalanceDto> _replaceClient(ClientWithBalanceDto client) {
    return state.clients.map((current) {
      if (current.client.id == client.client.id) {
        return client;
      }

      return current;
    }).toList();
  }
}
