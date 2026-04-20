import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../dtos/client_with_balance_dto.dart';
import '../../dtos/order_with_items_dto.dart';
import '../../models/product_model.dart';
import '../../services/orders_service.dart';
import '../clients/clients_provider.dart';
import '../products/products_provider.dart';

final ordersServiceProvider = Provider<OrdersService>((ref) {
  return OrdersService();
});

final ordersProvider = NotifierProvider<OrdersController, OrdersState>(
  OrdersController.new,
);

class OrdersState {
  const OrdersState({
    this.clients = const [],
    this.products = const [],
    this.cart = const [],
    this.selectedClientId,
    this.clientSearch = '',
    this.productSearch = '',
    this.note = '',
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.lastOrder,
  });

  final List<ClientWithBalanceDto> clients;
  final List<ProductModel> products;
  final List<OrderCartItem> cart;
  final String? selectedClientId;
  final String clientSearch;
  final String productSearch;
  final String note;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final OrderWithItemsDto? lastOrder;

  ClientWithBalanceDto? get selectedClient {
    for (final client in clients) {
      if (client.client.id == selectedClientId) {
        return client;
      }
    }

    return null;
  }

  List<ClientWithBalanceDto> get visibleClients {
    final search = clientSearch.trim().toLowerCase();
    return clients.where((item) {
      final client = item.client;
      if (!client.active) {
        return false;
      }

      if (search.isEmpty) {
        return true;
      }

      return client.name.toLowerCase().contains(search) ||
          (client.responsibleName ?? '').toLowerCase().contains(search) ||
          (client.responsibleWhatsapp ?? '').contains(search);
    }).toList();
  }

  List<ProductModel> get visibleProducts {
    final search = productSearch.trim().toLowerCase();
    if (search.isEmpty) {
      return products;
    }

    return products.where((product) {
      return product.name.toLowerCase().contains(search) ||
          (product.category?.name ?? '').toLowerCase().contains(search);
    }).toList();
  }

  int get totalCents {
    return cart.fold<int>(
      0,
      (total, item) => total + item.subtotalCents,
    );
  }

  int quantityForProduct(String productId) {
    for (final item in cart) {
      if (item.product.id == productId) {
        return item.quantity;
      }
    }

    return 0;
  }

  OrdersState copyWith({
    List<ClientWithBalanceDto>? clients,
    List<ProductModel>? products,
    List<OrderCartItem>? cart,
    String? selectedClientId,
    bool clearSelectedClient = false,
    String? clientSearch,
    String? productSearch,
    String? note,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    OrderWithItemsDto? lastOrder,
    bool clearLastOrder = false,
  }) {
    return OrdersState(
      clients: clients ?? this.clients,
      products: products ?? this.products,
      cart: cart ?? this.cart,
      selectedClientId:
          clearSelectedClient ? null : selectedClientId ?? this.selectedClientId,
      clientSearch: clientSearch ?? this.clientSearch,
      productSearch: productSearch ?? this.productSearch,
      note: note ?? this.note,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
      lastOrder: clearLastOrder ? null : lastOrder ?? this.lastOrder,
    );
  }
}

class OrderCartItem {
  const OrderCartItem({
    required this.product,
    required this.quantity,
  });

  final ProductModel product;
  final int quantity;

  int get subtotalCents => product.priceCents * quantity;
}

class OrdersController extends Notifier<OrdersState> {
  @override
  OrdersState build() {
    Future.microtask(loadData);

    return const OrdersState(isLoading: true);
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        ref.read(clientsServiceProvider).list(),
        ref.read(productsServiceProvider).listActive(),
      ]);

      state = state.copyWith(
        clients: results[0] as List<ClientWithBalanceDto>,
        products: results[1] as List<ProductModel>,
        isLoading: false,
        clearError: true,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
    }
  }

  void setClientSearch(String value) {
    state = state.copyWith(clientSearch: value);
  }

  void setProductSearch(String value) {
    state = state.copyWith(productSearch: value);
  }

  void selectClient(String? clientId) {
    state = state.copyWith(
      selectedClientId: clientId,
      clearSelectedClient: clientId == null || clientId.isEmpty,
    );
  }

  void setNote(String value) {
    state = state.copyWith(note: value);
  }

  void addProduct(ProductModel product) {
    final cart = [...state.cart];
    final index = cart.indexWhere((item) => item.product.id == product.id);

    if (index == -1) {
      cart.add(OrderCartItem(product: product, quantity: 1));
    } else {
      final item = cart[index];
      cart[index] = OrderCartItem(
        product: item.product,
        quantity: item.quantity + 1,
      );
    }

    state = state.copyWith(cart: cart, clearLastOrder: true);
  }

  void decrementProduct(String productId) {
    final cart = [...state.cart];
    final index = cart.indexWhere((item) => item.product.id == productId);
    if (index == -1) {
      return;
    }

    final item = cart[index];
    if (item.quantity <= 1) {
      cart.removeAt(index);
    } else {
      cart[index] = OrderCartItem(
        product: item.product,
        quantity: item.quantity - 1,
      );
    }

    state = state.copyWith(cart: cart);
  }

  void removeProduct(String productId) {
    state = state.copyWith(
      cart: state.cart.where((item) => item.product.id != productId).toList(),
    );
  }

  void clearCart() {
    state = state.copyWith(cart: const [], note: '', clearLastOrder: true);
  }

  Future<String?> submitOrder() async {
    final client = state.selectedClient;
    if (client == null) {
      return 'Selecione o cliente.';
    }

    if (state.cart.isEmpty) {
      return 'Adicione pelo menos um produto.';
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final order = await ref.read(ordersServiceProvider).create(
            clientId: client.client.id,
            note: state.note.trim().isEmpty ? null : state.note.trim(),
            items: state.cart.map((item) {
              return CreateOrderItemInput(
                productId: item.product.id,
                quantity: item.quantity,
              );
            }).toList(),
          );

      final updatedClient = ClientWithBalanceDto(
        client: client.client,
        balanceCents: client.balanceCents + order.totalCents,
      );

      state = state.copyWith(
        clients: state.clients.map((item) {
          return item.client.id == updatedClient.client.id ? updatedClient : item;
        }).toList(),
        clearSelectedClient: true,
        cart: const [],
        note: '',
        productSearch: '',
        isSaving: false,
        lastOrder: order,
        clearError: true,
      );

      return null;
    } on ApiException catch (error) {
      state = state.copyWith(isSaving: false, error: error.message);
      return error.message;
    }
  }
}
