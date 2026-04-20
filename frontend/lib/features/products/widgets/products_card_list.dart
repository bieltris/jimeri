import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../models/product_model.dart';
import 'product_status_chip.dart';

class ProductsCardList extends StatelessWidget {
  const ProductsCardList({
    required this.products,
    required this.onEdit,
    required this.onToggleStatus,
    super.key,
  });

  final List<ProductModel> products;
  final ValueChanged<ProductModel> onEdit;
  final ValueChanged<ProductModel> onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: products.map((product) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
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
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  ProductStatusChip(active: product.active),
                ],
              ),
              const SizedBox(height: 8),
              Text(product.category?.name ?? 'Sem categoria'),
              const SizedBox(height: 8),
              Text(
                formatCents(product.priceCents),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => onEdit(product),
                    child: const Text('Editar'),
                  ),
                  TextButton(
                    onPressed: () => onToggleStatus(product),
                    child: Text(
                      product.active ? 'Remover da venda' : 'Voltar a vender',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
