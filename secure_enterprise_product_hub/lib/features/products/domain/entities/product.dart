class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.category,
    this.imageUrl,
  });

  final String id;
  final String name;
  final double price;
  final String currency;
  final String category;
  final String? imageUrl;

  String get priceLabel =>
      '${ProductCurrencies.symbolFor(currency)}${price.toStringAsFixed(2)}';

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? currency,
    String? category,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class ProductCurrencies {
  static const values = ['USD', 'INR', 'EUR', 'GBP'];

  static String symbolFor(String value) {
    switch (value.toUpperCase()) {
      case 'INR':
        return 'Rs ';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '\$';
    }
  }
}

class ProductCategories {
  static const values = [
    'electronics',
    'apparel',
    'books',
    'furniture',
    'groceries',
    'tools',
    'other',
  ];
}

class ProductPage {
  const ProductPage({
    required this.products,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<Product> products;
  final int page;
  final int limit;
  final int total;

  bool get hasMore => page * limit < total;
}
