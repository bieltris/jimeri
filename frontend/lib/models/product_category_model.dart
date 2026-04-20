class ProductCategoryModel {
  const ProductCategoryModel({
    required this.id,
    required this.name,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final bool active;
  final String createdAt;
  final String updatedAt;

  factory ProductCategoryModel.fromJson(dynamic json) {
    final data = json as Map<String, dynamic>;

    return ProductCategoryModel(
      id: data['id'] as String,
      name: data['name'] as String,
      active: data['active'] as bool? ?? true,
      createdAt: data['createdAt'] as String? ?? '',
      updatedAt: data['updatedAt'] as String? ?? '',
    );
  }
}
