import 'product_category_model.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.priceCents,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  final String id;
  final String name;
  final ProductCategoryModel? category;
  final int priceCents;
  final bool active;
  final String createdAt;
  final String updatedAt;

  factory ProductModel.fromJson(dynamic json) {
    final data = json as Map<String, dynamic>;

    return ProductModel(
      id: data['id'] as String,
      name: data['name'] as String,
      category: data['category'] == null
          ? null
          : ProductCategoryModel.fromJson(data['category']),
      priceCents: data['priceCents'] as int,
      active: data['active'] as bool,
      createdAt: data['createdAt'] as String,
      updatedAt: data['updatedAt'] as String,
    );
  }
}
