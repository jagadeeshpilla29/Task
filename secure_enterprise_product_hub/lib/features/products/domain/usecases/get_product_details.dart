import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductDetails {
  GetProductDetails(this._repository);

  final ProductRepository _repository;

  Future<Product> call(String id) => _repository.getById(id);
}
