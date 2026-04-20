import '../core/api/api_client.dart';
import '../core/api/api_routes.dart';
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

  Future<ProductModel> create({
    required String name,
    required int priceCents,
    String? category,
  }) {
    return ApiClient.post<ProductModel>(
      ApiRoutes.products(),
      body: {
        'name': name,
        'category': category,
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
    String? category,
  }) {
    return ApiClient.put<ProductModel>(
      ApiRoutes.product(id),
      body: {
        'name': name,
        'category': category,
        'priceCents': priceCents,
        'active': active,
      },
      fromJson: ProductModel.fromJson,
    );
  }
}
