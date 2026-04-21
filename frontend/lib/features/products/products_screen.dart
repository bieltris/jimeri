import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared/admin_page.dart';
import '../../core/shared/app_snackbar.dart';
import '../../models/product_model.dart';
import 'products_provider.dart';
import 'widgets/product_form_dialog.dart';
import 'widgets/products_card_list.dart';
import 'widgets/products_table.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(productsProvider.notifier).loadProducts();
      await ref.read(productsProvider.notifier).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsProvider);
    final products = state.visibleProducts;

    return AdminPage(
      title: 'Produtos',
      description: 'Gerencie os itens vendidos na cantina.',
      onRefresh: _refreshPage,
      action: FilledButton.icon(
        onPressed: state.isSaving ? null : () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Novo produto'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductsFilters(state: state),
          const SizedBox(height: 20),
          if (state.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (products.isEmpty)
            const _EmptyProducts()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 760) {
                  return ProductsCardList(
                    products: products,
                    onEdit: (product) => _openForm(context, ref, product),
                    onToggleStatus: (product) =>
                        _toggleStatus(context, ref, product),
                  );
                }

                return ProductsTable(
                  products: products,
                  onEdit: (product) => _openForm(context, ref, product),
                  onToggleStatus: (product) =>
                      _toggleStatus(context, ref, product),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _refreshPage() async {
    await ref.read(productsProvider.notifier).loadProducts();
    await ref.read(productsProvider.notifier).loadCategories();
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, [
    ProductModel? product,
  ]) async {
    final input = await showDialog<ProductFormInput>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductFormDialog(product: product),
    );

    if (input == null || !context.mounted) {
      return;
    }

    final error = product == null
        ? await ref.read(productsProvider.notifier).createProduct(input)
        : await ref.read(productsProvider.notifier).updateProduct(
              product,
              input,
            );

    if (!context.mounted) {
      return;
    }

    if (error != null) {
      AppSnackBar.showError(error, context: context);
      return;
    }

    AppSnackBar.showSuccess(
      product == null ? 'Produto criado.' : 'Produto atualizado.',
      context: context,
    );
  }

  Future<void> _toggleStatus(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) async {
    final error = await ref
        .read(productsProvider.notifier)
        .toggleProductStatus(product);

    if (!context.mounted) {
      return;
    }

    if (error != null) {
      AppSnackBar.showError(error, context: context);
      return;
    }

    AppSnackBar.showSuccess(
      product.active ? 'Produto removido da venda.' : 'Produto voltou a venda.',
      context: context,
    );
  }
}

class _ProductsFilters extends ConsumerWidget {
  const _ProductsFilters({
    required this.state,
  });

  final ProductsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final searchWidth = constraints.maxWidth < 380
            ? constraints.maxWidth
            : 360.0;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: searchWidth,
              child: TextField(
                onChanged: ref.read(productsProvider.notifier).setSearch,
                decoration: const InputDecoration(
                  labelText: 'Buscar produto',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SegmentedButton<ProductsFilter>(
              segments: const [
                ButtonSegment(
                  value: ProductsFilter.all,
                  label: Text('Todos'),
                ),
                ButtonSegment(
                  value: ProductsFilter.active,
                  label: Text('A venda'),
                ),
                ButtonSegment(
                  value: ProductsFilter.inactive,
                  label: Text('Fora da venda'),
                ),
              ],
              selected: {state.filter},
              onSelectionChanged: (values) {
                ref.read(productsProvider.notifier).setFilter(values.first);
              },
            ),
          ],
        );
      },
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
            'Nenhum produto encontrado.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Cadastre o primeiro item vendido na cantina.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
