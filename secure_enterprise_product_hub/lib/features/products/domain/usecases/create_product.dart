import '../repositories/product_repository.dart';

class CreateProduct {
  CreateProduct(this._repository);

  final ProductRepository _repository;

  Future<String> call({
    required String name,
    required double price,
    required String currency,
    required String category,
  }) {
    return _repository.create(
      name: name,
      price: price,
      currency: currency,
      category: category,
    );
  }
}
