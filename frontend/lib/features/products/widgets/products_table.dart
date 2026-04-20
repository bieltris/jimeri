import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../models/product_model.dart';
import 'product_status_chip.dart';

class ProductsTable extends StatelessWidget {
  const ProductsTable({
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Produto')),
              DataColumn(label: Text('Categoria')),
              DataColumn(label: Text('Preco')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Acoes')),
            ],
            rows: products.map((product) {
              return DataRow(
                cells: [
                  DataCell(Text(product.name)),
                  DataCell(Text(product.category ?? '-')),
                  DataCell(Text(formatCents(product.priceCents))),
                  DataCell(ProductStatusChip(active: product.active)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => onEdit(product),
                          child: const Text('Editar'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => onToggleStatus(product),
                          child: Text(product.active ? 'Desativar' : 'Ativar'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
