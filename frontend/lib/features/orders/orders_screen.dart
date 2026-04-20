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
      floatingOverlay: _MobileCartOverlay(state: state),
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
                      const SizedBox(height: 92),
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

class _MobileCartOverlay extends ConsumerStatefulWidget {
  const _MobileCartOverlay({
    required this.state,
  });

  final OrdersState state;

  @override
  ConsumerState<_MobileCartOverlay> createState() => _MobileCartOverlayState();
}

class _MobileCartOverlayState extends ConsumerState<_MobileCartOverlay> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 920 || widget.state.isLoading || widget.state.selectedClient == null) {
          return const SizedBox();
        }

        final height = _expanded ? constraints.maxHeight * 0.70 : 66.0;

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: double.infinity,
              height: height,
              decoration: BoxDecoration(
                color: _floatingCartColor(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _floatingCartBorderColor(context)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _MobileCartHeader(
                    state: widget.state,
                    expanded: _expanded,
                    onTap: () {
                      setState(() {
                        _expanded = !_expanded;
                      });
                    },
                  ),
                  if (_expanded)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: _CartPanel(state: widget.state),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MobileCartHeader extends StatelessWidget {
  const _MobileCartHeader({
    required this.state,
    required this.expanded,
    required this.onTap,
  });

  final OrdersState state;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final clientName = state.selectedClient?.client.name ?? 'Sem cliente';
    final itemCount = state.cart.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$itemCount itens - ${formatCents(state.totalCents)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
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
        color: _cardColor(context),
        border: Border.all(color: _borderColor(context)),
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
        color: hasDebt
            ? _softWarningColor(context)
            : _softSuccessColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        hasDebt
            ? 'Divida atual: ${formatCents(client.balanceCents)}'
            : 'Sem divida aberta.',
        style: TextStyle(
          color: hasDebt
              ? _warningTextColor(context)
              : _successTextColor(context),
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
        final columns = width >= 680
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
            mainAxisExtent: columns == 1 ? 162 : 188,
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
              onRemove: () => ref
                  .read(ordersProvider.notifier)
                  .decrementProduct(product.id),
              onAdd: () => ref.read(ordersProvider.notifier).addProduct(product),
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
    required this.onRemove,
    required this.onAdd,
  });

  final ProductModel product;
  final int quantity;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final hasQuantity = quantity > 0;

    return Container(
      decoration: BoxDecoration(
        color: hasQuantity ? _selectedProductColor(context) : _cardColor(context),
        border: Border.all(
          color: hasQuantity ? AppColors.primary : _borderColor(context),
          width: hasQuantity ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: _ProductActionButton(
                    icon: Icons.remove,
                    label: 'Remover',
                    backgroundColor: AppColors.error,
                    onPressed: hasQuantity ? onRemove : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ProductActionButton(
                    icon: Icons.add,
                    label: 'Adicionar',
                    backgroundColor: AppColors.accent,
                    onPressed: onAdd,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductActionButton extends StatelessWidget {
  const _ProductActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor.withOpacity(0.26),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
        color: _cardColor(context),
        border: Border.all(color: _borderColor(context)),
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
            backgroundColor: AppColors.error,
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
            backgroundColor: AppColors.accent,
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
    required this.backgroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 34,
      child: IconButton.filled(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
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
        color: _subtleCardColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor(context)),
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
        color: _softWarningColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: _warningTextColor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _cardColor(BuildContext context) {
  return Theme.of(context).colorScheme.surface;
}

Color _subtleCardColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.neutral950 : AppColors.neutral50;
}

Color _borderColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.neutral600 : AppColors.neutral200;
}

Color _selectedProductColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark
      ? AppColors.primaryDark.withOpacity(0.28)
      : AppColors.primaryLight;
}

Color _softSuccessColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.accentDark.withOpacity(0.24) : AppColors.accentLight;
}

Color _successTextColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.accentLight : AppColors.accentDark;
}

Color _softWarningColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return AppColors.warning.withOpacity(isDark ? 0.22 : 0.14);
}

Color _warningTextColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? Colors.white : AppColors.neutral950;
}

Color _floatingCartColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.neutralBlue : AppColors.primary;
}

Color _floatingCartBorderColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.primaryLight.withOpacity(0.38) : AppColors.primaryDark;
}
