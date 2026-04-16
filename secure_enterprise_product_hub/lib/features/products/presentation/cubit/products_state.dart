import '../../domain/entities/product.dart';

class ProductsState {
  const ProductsState({
    required this.status,
    this.products = const [],
    this.page = 1,
    this.limit = 10,
    this.total = 0,
    this.search = '',
    this.category = '',
    this.message,
    this.selected,
  });

  final ProductsStatus status;
  final List<Product> products;
  final int page;
  final int limit;
  final int total;
  final String search;
  final String category;
  final String? message;
  final Product? selected;

  bool get hasMore => page * limit < total;

  ProductsState copyWith({
    ProductsStatus? status,
    List<Product>? products,
    int? page,
    int? limit,
    int? total,
    String? search,
    String? category,
    String? message,
    Product? selected,
    bool clearMessage = false,
    bool clearSelected = false,
  }) {
    return ProductsState(
      status: status ?? this.status,
      products: products ?? this.products,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      search: search ?? this.search,
      category: category ?? this.category,
      message: clearMessage ? null : message ?? this.message,
      selected: clearSelected ? null : selected ?? this.selected,
    );
  }
}

enum ProductsStatus { initial, loading, ready, saving, failure }
