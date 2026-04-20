import 'package:flutter/material.dart';

import '../../../core/utils/money.dart';
import '../../../models/product_model.dart';
import '../products_provider.dart';

class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({
    this.product,
    super.key,
  });

  final ProductModel? product;

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();

  bool _active = true;

  @override
  void initState() {
    super.initState();

    final product = widget.product;
    if (product == null) {
      return;
    }

    _nameController.text = product.name;
    _categoryController.text = product.category ?? '';
    _priceController.text = formatCents(product.priceCents).replaceAll('R\$ ', '');
    _active = product.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar produto' : 'Novo produto'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
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
              TextFormField(
                controller: _categoryController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category_outlined),
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
                  title: const Text('Produto ativo'),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
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

    final category = _categoryController.text.trim();

    Navigator.of(context).pop(
      ProductFormInput(
        name: _nameController.text.trim(),
        category: category.isEmpty ? null : category,
        priceCents: parseCents(_priceController.text)!,
        active: _active,
      ),
    );
  }
}
