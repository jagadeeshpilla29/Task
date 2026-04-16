import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
    required super.currency,
    required super.category,
    super.imageUrl,
  });

  factory ProductModel.fromJson(
    Map<String, dynamic> json, {
    String Function(String? url)? imageResolver,
  }) {
    final rawImageUrl = json['imageUrl']?.toString();
    return ProductModel(
      id: json['id'].toString(),
      name: json['name'].toString(),
      price: (json['price'] as num).toDouble(),
      currency: json['currency']?.toString() ?? 'USD',
      category: json['category'].toString(),
      imageUrl: imageResolver == null
          ? rawImageUrl
          : imageResolver(rawImageUrl),
    );
  }
}

class ProductPageModel extends ProductPage {
  const ProductPageModel({
    required super.products,
    required super.page,
    required super.limit,
    required super.total,
  });

  factory ProductPageModel.fromJson(
    Map<String, dynamic> json, {
    required String Function(String? url) imageResolver,
  }) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    return ProductPageModel(
      products: (json['products'] as List<dynamic>)
          .map(
            (item) => ProductModel.fromJson(
              item as Map<String, dynamic>,
              imageResolver: imageResolver,
            ),
          )
          .toList(),
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
    );
  }
}
