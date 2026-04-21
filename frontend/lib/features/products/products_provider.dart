import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../models/product_category_model.dart';
import '../../models/product_model.dart';
import '../../services/products_service.dart';

final productsServiceProvider = Provider<ProductsService>((ref) {
  return ProductsService();
});

final productsProvider = NotifierProvider<ProductsController, ProductsState>(
  ProductsController.new,
);

enum ProductsFilter {
  all,
  active,
  inactive,
}

class ProductsState {
  const ProductsState({
    this.products = const [],
    this.categories = const [],
    this.search = '',
    this.filter = ProductsFilter.active,
    this.isLoading = false,
    this.isLoadingCategories = false,
    this.isSaving = false,
    this.error,
  });

  final List<ProductModel> products;
  final List<ProductCategoryModel> categories;
  final String search;
  final ProductsFilter filter;
  final bool isLoading;
  final bool isLoadingCategories;
  final bool isSaving;
  final String? error;

  List<ProductModel> get visibleProducts {
    return products.where((product) {
      return switch (filter) {
        ProductsFilter.all => true,
        ProductsFilter.active => product.active,
        ProductsFilter.inactive => !product.active,
      };
    }).toList();
  }

  ProductsState copyWith({
    List<ProductModel>? products,
    List<ProductCategoryModel>? categories,
    String? search,
    ProductsFilter? filter,
    bool? isLoading,
    bool? isLoadingCategories,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return ProductsState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      search: search ?? this.search,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class ProductFormInput {
  const ProductFormInput({
    required this.name,
    required this.priceCents,
    required this.active,
    this.categoryId,
  });

  final String name;
  final String? categoryId;
  final int priceCents;
  final bool active;
}

class ProductsController extends Notifier<ProductsState> {
  Timer? _searchDebounce;

  @override
  ProductsState build() {
    ref.onDispose(() {
      _searchDebounce?.cancel();
    });

    return const ProductsState(isLoading: true);
  }

  Future<void> loadCategories() async {
    state = state.copyWith(isLoadingCategories: true, clearError: true);

    try {
      final categories = await ref.read(productsServiceProvider).listCategories();

      state = state.copyWith(
        categories: categories,
        isLoadingCategories: false,
        clearError: true,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        isLoadingCategories: false,
        error: error.message,
      );
    }
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final products = await ref.read(productsServiceProvider).list(
            search: state.search.trim(),
          );

      state = state.copyWith(
        products: products,
        isLoading: false,
        clearError: true,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.message,
      );
    }
  }

  void setSearch(String value) {
    state = state.copyWith(search: value);

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), loadProducts);
  }

  void setFilter(ProductsFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<String?> createProduct(ProductFormInput input) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final product = await ref.read(productsServiceProvider).create(
            name: input.name,
            categoryId: input.categoryId,
            priceCents: input.priceCents,
          );

      state = state.copyWith(
        products: [product, ...state.products],
        isSaving: false,
        clearError: true,
      );

      return null;
    } on ApiException catch (error) {
      state = state.copyWith(isSaving: false, error: error.message);

      return error.message;
    }
  }

  Future<String?> updateProduct(
    ProductModel product,
    ProductFormInput input,
  ) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final updated = await ref.read(productsServiceProvider).update(
            id: product.id,
            name: input.name,
            categoryId: input.categoryId,
            priceCents: input.priceCents,
            active: input.active,
          );

      state = state.copyWith(
        products: _replaceProduct(updated),
        isSaving: false,
        clearError: true,
      );

      return null;
    } on ApiException catch (error) {
      state = state.copyWith(isSaving: false, error: error.message);

      return error.message;
    }
  }

  Future<String?> toggleProductStatus(ProductModel product) async {
    final updatedProducts = state.products.map((current) {
      if (current.id != product.id) {
        return current;
      }

      return ProductModel(
        id: product.id,
        name: product.name,
        category: product.category,
        priceCents: product.priceCents,
        active: !product.active,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      );
    }).toList();

    state = state.copyWith(products: updatedProducts, clearError: true);

    try {
      final updated = await ref.read(productsServiceProvider).update(
            id: product.id,
            name: product.name,
            categoryId: product.category?.id,
            priceCents: product.priceCents,
            active: !product.active,
          );

      state = state.copyWith(products: _replaceProduct(updated));

      return null;
    } on ApiException catch (error) {
      state = state.copyWith(
        products: _replaceProduct(product),
        error: error.message,
      );

      return error.message;
    }
  }

  List<ProductModel> _replaceProduct(ProductModel product) {
    return state.products.map((current) {
      if (current.id == product.id) {
        return product;
      }

      return current;
    }).toList();
  }

  Future<ProductCategoryModel?> createCategory(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      state = state.copyWith(error: 'Informe o nome da categoria.');
      return null;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final category = await ref.read(productsServiceProvider).createCategory(
            name: normalizedName,
          );

      state = state.copyWith(
        categories: [category, ...state.categories],
        isSaving: false,
        clearError: true,
      );

      return category;
    } on ApiException catch (error) {
      state = state.copyWith(isSaving: false, error: error.message);

      return null;
    }
  }
}
