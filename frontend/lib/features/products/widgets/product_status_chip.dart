import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ProductStatusChip extends StatelessWidget {
  const ProductStatusChip({
    required this.active,
    super.key,
  });

  final bool active;

  @override
  Widget build(BuildContext context) {
    final background = active ? AppColors.accentLight : AppColors.neutral200;
    final foreground = active ? AppColors.accentDark : AppColors.neutral600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        active ? 'Ativo' : 'Inativo',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
