import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/shared/adaptive_form_sheet.dart';
import '../../../core/shared/app_snackbar.dart';
import '../../../core/shared/responsive_dialog.dart';
import '../../../core/utils/money.dart';
import '../../../models/product_category_model.dart';
import '../../../models/product_model.dart';
import '../products_provider.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  const ProductFormDialog({
    this.product,
    super.key,
  });

  final ProductModel? product;

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  String? _categoryId;
  bool _active = true;

  @override
  void initState() {
    super.initState();

    final product = widget.product;
    if (product == null) {
      return;
    }

    _nameController.text = product.name;
    _categoryId = product.category?.id;
    _priceController.text = formatCents(product.priceCents).replaceAll('R\$ ', '');
    _active = product.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final productsState = ref.watch(productsProvider);

    return AdaptiveFormContainer(
      title: Text(isEditing ? 'Editar produto' : 'Novo produto'),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoryId ?? '',
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Categoria (opcional)',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Sem categoria'),
                ),
                ...productsState.categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  );
                }),
              ],
              onChanged: productsState.isLoadingCategories
                  ? null
                  : (value) {
                      setState(() {
                        _categoryId = value == '' ? null : value;
                      });
                    },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: productsState.isSaving ? null : _createCategory,
                icon: const Icon(Icons.add),
                label: const Text('Criar categoria'),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Preco',
                prefixText: 'R\$ ',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (value) {
                final cents = parseCents(value ?? '');
                if (cents == null) {
                  return 'Informe um preco valido.';
                }

                return null;
              },
            ),
            if (isEditing) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Produto a venda'),
                value: _active,
                onChanged: (value) {
                  setState(() {
                    _active = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      ProductFormInput(
        name: _nameController.text.trim(),
        categoryId: _categoryId,
        priceCents: parseCents(_priceController.text)!,
        active: _active,
      ),
    );
  }

  Future<void> _createCategory() async {
    final category = await showDialog<ProductCategoryModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _CreateCategoryDialog(),
    );

    if (category == null || !mounted) {
      return;
    }

    setState(() {
      _categoryId = category.id;
    });

    AppSnackBar.showSuccess('Categoria criada.', context: context);
  }
}

class _CreateCategoryDialog extends ConsumerStatefulWidget {
  const _CreateCategoryDialog();

  @override
  ConsumerState<_CreateCategoryDialog> createState() =>
      _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends ConsumerState<_CreateCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsProvider);

    return ResponsiveDialog(
      title: const Text('Criar categoria'),
      child: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome da categoria',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Informe o nome.';
            }

            return null;
          },
        ),
      ),
      actions: [
        FilledButton(
          onPressed: state.isSaving ? null : _submit,
          child: state.isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final category = await ref
        .read(productsProvider.notifier)
        .createCategory(_nameController.text);

    if (!mounted) {
      return;
    }

    if (category == null) {
      final error =
          ref.read(productsProvider).error ?? 'Nao foi possivel criar categoria.';
      AppSnackBar.showError(error, context: context);
      return;
    }

    Navigator.of(context).pop(category);
  }
}
