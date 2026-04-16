import '../repositories/product_repository.dart';

class UpdateProduct {
  UpdateProduct(this._repository);

  final ProductRepository _repository;

  Future<void> call({
    required String id,
    required String name,
    required double price,
    required String currency,
    required String category,
  }) {
    return _repository.update(
      id: id,
      name: name,
      price: price,
      currency: currency,
      category: category,
    );
  }
}
