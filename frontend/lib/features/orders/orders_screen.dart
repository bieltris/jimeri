import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared/admin_page.dart';
import '../../core/shared/app_snackbar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../dtos/client_with_balance_dto.dart';
import '../../models/product_model.dart';
import 'orders_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersProvider);

    return AdminPage(
      title: 'Lancar pedido',
      description: 'Monte a compra rapido e finalize sem sair da tela.',
      action: IconButton.filledTonal(
        tooltip: 'Atualizar dados',
        onPressed:
            state.isLoading ? null : ref.read(ordersProvider.notifier).loadData,
        icon: const Icon(Icons.refresh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.error != null) ...[
            _WarningBar(message: state.error!),
            const SizedBox(height: 16),
          ],
          if (state.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 920;

                if (!isWide) {
                  return Column(
                    children: [
                      _SaleBoard(state: state),
                      const SizedBox(height: 16),
                      _CartPanel(state: state),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _SaleBoard(state: state)),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 360,
                      child: _CartPanel(state: state),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SaleBoard extends ConsumerWidget {
  const _SaleBoard({
    required this.state,
  });

  final OrdersState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ClientPicker(state: state),
        const SizedBox(height: 20),
        TextField(
          onChanged: ref.read(ordersProvider.notifier).setProductSearch,
          decoration: const InputDecoration(
            labelText: 'Buscar produto',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        if (state.visibleProducts.isEmpty)
          const _EmptyProducts()
        else
          _ProductsGrid(products: state.visibleProducts),
      ],
    );
  }
}

class _ClientPicker extends ConsumerWidget {
  const _ClientPicker({
    required this.state,
  });

  final OrdersState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = _clientOptions(state);
    final selectedClient = state.selectedClient;
    final selectedValue = clients.any(
      (item) => item.client.id == state.selectedClientId,
    )
        ? state.selectedClientId
        : null;

    return Container(
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 620;

              final search = TextField(
                onChanged: ref.read(ordersProvider.notifier).setClientSearch,
                decoration: const InputDecoration(
                  labelText: 'Buscar por aluno, mae ou WhatsApp',
                  prefixIcon: Icon(Icons.person_search),
                ),
              );

              final dropdown = DropdownButtonFormField<String>(
                value: selectedValue,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Selecionar cliente',
                ),
                items: clients.map((item) {
                  return DropdownMenuItem(
                    value: item.client.id,
                    child: Text(
                      '${item.client.name} - ${formatCents(item.balanceCents)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: ref.read(ordersProvider.notifier).selectClient,
              );

              if (!isWide) {
                return Column(
                  children: [
                    search,
                    const SizedBox(height: 12),
                    dropdown,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 12),
                  Expanded(child: dropdown),
                ],
              );
            },
          ),
          if (selectedClient != null) ...[
            const SizedBox(height: 12),
            _ClientDebtStrip(client: selectedClient),
          ],
        ],
      ),
    );
  }

  List<ClientWithBalanceDto> _clientOptions(OrdersState state) {
    final visible = state.visibleClients.take(80).toList();
    final selected = state.selectedClient;

    if (selected == null ||
        visible.any((item) => item.client.id == selected.client.id)) {
      return visible;
    }

    return [selected, ...visible];
  }
}

class _ClientDebtStrip extends StatelessWidget {
  const _ClientDebtStrip({
    required this.client,
  });

  final ClientWithBalanceDto client;

  @override
  Widget build(BuildContext context) {
    final hasDebt = client.balanceCents > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasDebt ? AppColors.warning.withOpacity(0.14) : AppColors.accentLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        hasDebt
            ? 'Divida atual: ${formatCents(client.balanceCents)}'
            : 'Sem divida aberta.',
        style: TextStyle(
          color: hasDebt ? AppColors.neutral950 : AppColors.accentDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProductsGrid extends ConsumerWidget {
  const _ProductsGrid({
    required this.products,
  });

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 920
            ? 4
            : width >= 680
                ? 3
                : width >= 440
                    ? 2
                    : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: columns == 1 ? 132 : 152,
          ),
          itemBuilder: (context, index) {
            final product = products[index];

            return _ProductButton(
              product: product,
              quantity: ref.watch(
                ordersProvider.select(
                  (state) => state.quantityForProduct(product.id),
                ),
              ),
              onTap: () {
                ref.read(ordersProvider.notifier).addProduct(product);
              },
            );
          },
        );
      },
    );
  }
}

class _ProductButton extends StatelessWidget {
  const _ProductButton({
    required this.product,
    required this.quantity,
    required this.onTap,
  });

  final ProductModel product;
  final int quantity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasQuantity = quantity > 0;

    return Material(
      color: hasQuantity ? AppColors.primaryLight : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasQuantity ? AppColors.primary : AppColors.neutral200,
              width: hasQuantity ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  if (hasQuantity)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'x$quantity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                product.category?.name ?? 'Sem categoria',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Text(
                formatCents(product.priceCents),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartPanel extends ConsumerWidget {
  const _CartPanel({
    required this.state,
  });

  final OrdersState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSubmit = state.selectedClient != null &&
        state.cart.isNotEmpty &&
        !state.isSaving;

    return Container(
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pedido atual',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (state.cart.isNotEmpty)
                TextButton(
                  onPressed: state.isSaving
                      ? null
                      : ref.read(ordersProvider.notifier).clearCart,
                  child: const Text('Limpar'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.cart.isEmpty)
            const _EmptyCart()
          else ...[
            ...state.cart.map((item) => _CartItemRow(item: item)),
            const Divider(height: 24),
            TextField(
              minLines: 2,
              maxLines: 3,
              onChanged: ref.read(ordersProvider.notifier).setNote,
              decoration: const InputDecoration(
                labelText: 'Observacao',
                hintText: 'Ex: entregar no intervalo',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  formatCents(state.totalCents),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: canSubmit
                  ? () async {
                      final error =
                          await ref.read(ordersProvider.notifier).submitOrder();

                      if (!context.mounted) {
                        return;
                      }

                      if (error != null) {
                        AppSnackBar.showError(error, context: context);
                        return;
                      }

                      AppSnackBar.showSuccess(
                        'Pedido lancado.',
                        context: context,
                      );
                    }
                  : null,
              icon: state.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(state.isSaving ? 'Lancando...' : 'Finalizar pedido'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CartItemRow extends ConsumerWidget {
  const _CartItemRow({
    required this.item,
  });

  final OrderCartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(formatCents(item.subtotalCents)),
              ],
            ),
          ),
          _QuantityButton(
            icon: Icons.remove,
            onPressed: () => ref
                .read(ordersProvider.notifier)
                .decrementProduct(item.product.id),
          ),
          SizedBox(
            width: 34,
            child: Text(
              item.quantity.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          _QuantityButton(
            icon: Icons.add,
            onPressed: () => ref
                .read(ordersProvider.notifier)
                .addProduct(item.product),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 34,
      child: IconButton.outlined(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhum produto ativo encontrado.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Ative ou cadastre produtos antes de lancar pedidos.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Toque em um produto para adicionar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _WarningBar extends StatelessWidget {
  const _WarningBar({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.neutral950,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
