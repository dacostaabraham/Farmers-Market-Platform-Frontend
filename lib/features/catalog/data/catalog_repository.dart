import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

// ── Models ──────────────────────────────────────────────────────────────

class Category {
  final int id;
  final String name;
  final int? parentId;
  final int level;
  final List<Category> children;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
    required this.level,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id:       json['id'],
    name:     json['name'],
    parentId: json['parent_id'],
    level:    json['level'] ?? 1,
    children: (json['all_children'] as List? ?? [])
                .map((c) => Category.fromJson(c))
                .toList(),
  );
}

class Product {
  final int id;
  final String name;
  final String? description;
  final int priceFcfa;
  final String unit;
  final int categoryId;
  final String? categoryName;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.priceFcfa,
    required this.unit,
    required this.categoryId,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id:           json['id'],
    name:         json['name'],
    description:  json['description'],
    priceFcfa:    json['price_fcfa'],
    unit:         json['unit'] ?? 'unité',
    categoryId:   json['category_id'],
    categoryName: json['category']?['name'],
  );
}

// ── Repository ──────────────────────────────────────────────────────────

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.read(apiClientProvider)),
);

class CatalogRepository {
  final ApiClient _api;
  CatalogRepository(this._api);

  Future<List<Category>> getCategoryTree() async {
    final res = await _api.get('/categories/tree');
    final list = res.data['data'] as List;
    return list.map((e) => Category.fromJson(e)).toList();
  }

  Future<List<Product>> getProducts({int? categoryId}) async {
    final res = await _api.get('/products', queryParams: categoryId != null ? {'category_id': categoryId} : null);
    final list = res.data['data'] as List;
    return list.map((e) => Product.fromJson(e)).toList();
  }

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final res = await _api.get('/categories/$categoryId/products');
    final list = res.data['data'] as List;
    return list.map((e) => Product.fromJson(e)).toList();
  }
}

// ── Providers ──────────────────────────────────────────────────────────

final categoryTreeProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(catalogRepositoryProvider).getCategoryTree();
});

final productsByCategoryProvider = FutureProvider.family<List<Product>, int>((ref, categoryId) async {
  return ref.read(catalogRepositoryProvider).getProductsByCategory(categoryId);
});

final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.read(catalogRepositoryProvider).getProducts();
});
