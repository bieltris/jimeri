import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../dtos/client_with_balance_dto.dart';
import '../../services/clients_service.dart';

final clientsServiceProvider = Provider<ClientsService>((ref) {
  return ClientsService();
});

final clientsProvider = NotifierProvider<ClientsController, ClientsState>(
  ClientsController.new,
);

enum ClientsFilter {
  all,
  active,
  inactive,
  withDebt,
}

class ClientsState {
  const ClientsState({
    this.clients = const [],
    this.search = '',
    this.filter = ClientsFilter.all,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final List<ClientWithBalanceDto> clients;
  final String search;
  final ClientsFilter filter;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  List<ClientWithBalanceDto> get visibleClients {
    return clients.where((item) {
      return switch (filter) {
        ClientsFilter.all => true,
        ClientsFilter.active => item.client.active,
        ClientsFilter.inactive => !item.client.active,
        ClientsFilter.withDebt => item.balanceCents > 0,
      };
    }).toList();
  }

  ClientsState copyWith({
    List<ClientWithBalanceDto>? clients,
    String? search,
    ClientsFilter? filter,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return ClientsState(
      clients: clients ?? this.clients,
      search: search ?? this.search,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class ClientFormInput {
  const ClientFormInput({
    required this.name,
    required this.active,
    this.responsibleName,
    this.responsibleWhatsapp,
    this.note,
  });

  final String name;
  final String? responsibleName;
  final String? responsibleWhatsapp;
  final String? note;
  final bool active;
}

class ClientsController extends Notifier<ClientsState> {
  Timer? _searchDebounce;

  @override
  ClientsState build() {
    ref.onDispose(() {
      _searchDebounce?.cancel();
    });

    Future.microtask(loadClients);

    return const ClientsState(isLoading: true);
  }

  Future<void> loadClients() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final clients = await ref.read(clientsServiceProvider).list(
            search: state.search.trim(),
          );

      state = state.copyWith(
        clients: clients,
        isLoading: false,
        clearError: true,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
    }
  }

  void setSearch(String value) {
    state = state.copyWith(search: value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), loadClients);
  }

  void setFilter(ClientsFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<String?> createClient(ClientFormInput input) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final client = await ref.read(clientsServiceProvider).create(
            name: input.name,
            responsibleName: input.responsibleName,
            responsibleWhatsapp: input.responsibleWhatsapp,
            note: input.note,
          );

      state = state.copyWith(
        clients: [client, ...state.clients],
        isSaving: false,
        clearError: true,
      );

      return null;
    } on ApiException catch (error) {
      state = state.copyWith(isSaving: false, error: error.message);
      return error.message;
    }
  }

  Future<String?> updateClient(
    ClientWithBalanceDto current,
    ClientFormInput input,
  ) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final updated = await ref.read(clientsServiceProvider).update(
            id: current.client.id,
            name: input.name,
            responsibleName: input.responsibleName,
            responsibleWhatsapp: input.responsibleWhatsapp,
            note: input.note,
            active: input.active,
          );

      state = state.copyWith(
        clients: _replaceClient(updated),
        isSaving: false,
        clearError: true,
      );

      return null;
    } on ApiException catch (error) {
      state = state.copyWith(isSaving: false, error: error.message);
      return error.message;
    }
  }

  Future<String?> toggleClientStatus(ClientWithBalanceDto current) {
    return updateClient(
      current,
      ClientFormInput(
        name: current.client.name,
        responsibleName: current.client.responsibleName,
        responsibleWhatsapp: current.client.responsibleWhatsapp,
        note: current.client.note,
        active: !current.client.active,
      ),
    );
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
