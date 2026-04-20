import '../core/api/api_client.dart';
import '../core/api/api_routes.dart';
import '../models/product_category_model.dart';
import '../models/product_model.dart';

class ProductsService {
  Future<List<ProductModel>> list({
    String? search,
  }) {
    return ApiClient.get<List<ProductModel>>(
      ApiRoutes.products(search: search),
      fromJson: ApiClient.listFromJson(ProductModel.fromJson),
    );
  }

  Future<List<ProductModel>> listActive() {
    return ApiClient.get<List<ProductModel>>(
      ApiRoutes.activeProducts(),
      fromJson: ApiClient.listFromJson(ProductModel.fromJson),
    );
  }

  Future<ProductModel> create({
    required String name,
    required int priceCents,
    String? categoryId,
  }) {
    return ApiClient.post<ProductModel>(
      ApiRoutes.products(),
      body: {
        'name': name,
        'categoryId': categoryId,
        'priceCents': priceCents,
      },
      fromJson: ProductModel.fromJson,
    );
  }

  Future<ProductModel> update({
    required String id,
    required String name,
    required int priceCents,
    required bool active,
    String? categoryId,
  }) {
    return ApiClient.put<ProductModel>(
      ApiRoutes.product(id),
      body: {
        'name': name,
        'categoryId': categoryId,
        'priceCents': priceCents,
        'active': active,
      },
      fromJson: ProductModel.fromJson,
    );
  }

  Future<List<ProductCategoryModel>> listCategories({
    String? search,
  }) {
    return ApiClient.get<List<ProductCategoryModel>>(
      ApiRoutes.productCategories(search: search),
      fromJson: ApiClient.listFromJson(ProductCategoryModel.fromJson),
    );
  }

  Future<ProductCategoryModel> createCategory({
    required String name,
  }) {
    return ApiClient.post<ProductCategoryModel>(
      ApiRoutes.productCategories(),
      body: {
        'name': name,
      },
      fromJson: ProductCategoryModel.fromJson,
    );
  }
}
