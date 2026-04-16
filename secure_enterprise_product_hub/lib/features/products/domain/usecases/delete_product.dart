import '../repositories/product_repository.dart';

class DeleteProduct {
  DeleteProduct(this._repository);

  final ProductRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
